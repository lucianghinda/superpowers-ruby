#!/usr/bin/env ruby
# frozen_string_literal: true

# Copies the main working tree's development SQLite databases into an
# existing git worktree's storage/ directory, handling Rails 8 multi-DB
# (Solid Queue/Cache/Cable) layouts and WAL journal mode.
#
# Usage: ruby create_sqlite_worktree.rb <worktree-path>
#
# Run from the main working directory (the source of truth), not from
# inside the worktree. Reads config/database.yml relative to cwd.
#
# Design note — why `cp` + `PRAGMA wal_checkpoint(TRUNCATE)` and not
# `sqlite3 <db> ".backup <target>"`:
# SQLite's native `.backup` is atomic and doesn't require manual WAL
# sidecar handling. We use cp + checkpoint because (a) it matches the
# proven postcraftstudio/bin/worktree source, (b) worktree creation
# typically happens with no concurrent writer, and (c) avoids shelling
# out to sqlite3 once per DB for the copy itself (only once for the
# checkpoint). If you need atomicity under concurrent writes, switch to
# `Open3.capture3("sqlite3", db, ".backup #{target}")`.

require "fileutils"
require "open3"
require "yaml"
require "erb"

class SqliteWorktreePopulator
  DEFAULT_ENV = "development"

  attr_reader :worktree_path

  def initialize(args)
    @raw_args = args
    @worktree_path = nil
  end

  def call
    validate_arguments!
    validate_database_yml!
    validate_sqlite_adapter!
    validate_sqlite_cli!
    resolve_and_validate_worktree!
    checkpoint_wal_files
    copy_databases
    print_summary
    0
  rescue CleanExit => e
    warn e.message if e.message
    e.exit_code
  end

  class CleanExit < StandardError
    attr_reader :exit_code

    def initialize(message, exit_code:)
      super(message)
      @exit_code = exit_code
    end
  end

  private

  def fail!(message)
    raise CleanExit.new(message, exit_code: 1)
  end

  def skip!(message)
    puts message
    raise CleanExit.new(nil, exit_code: 0)
  end

  def validate_arguments!
    return if @raw_args.size == 1

    fail! "Usage: ruby create_sqlite_worktree.rb <worktree-path>"
  end

  def validate_database_yml!
    return if File.exist?("config/database.yml")

    fail! "config/database.yml not found — is this a Rails project? " \
          "(run from the main working directory, not inside the worktree)"
  end

  def validate_sqlite_adapter!
    return if File.read("config/database.yml").include?("adapter: sqlite3")

    skip! "No SQLite adapter in config/database.yml — skipping (not a SQLite project)."
  end

  def validate_sqlite_cli!
    return if system("command -v sqlite3 >/dev/null 2>&1")

    fail! "sqlite3 CLI not found. Install it:\n" \
          "  macOS:  brew install sqlite3\n" \
          "  Debian: apt install sqlite3"
  end

  def resolve_and_validate_worktree!
    candidate = File.expand_path(@raw_args.first)

    unless Dir.exist?(candidate)
      fail! "Worktree path does not exist: #{candidate}\n" \
            "Create the worktree first (e.g., via the using-git-worktrees skill)."
    end

    _stdout, _stderr, status = Open3.capture3(
      "git", "-C", candidate, "rev-parse", "--is-inside-work-tree"
    )

    unless status.success?
      fail! "#{candidate} is not a git worktree. Refusing to write files outside a worktree."
    end

    @worktree_path = candidate
  end

  def database_paths
    @database_paths ||= begin
      yaml = YAML.safe_load(
        ERB.new(File.read("config/database.yml")).result,
        permitted_classes: [ Symbol ],
        aliases: true
      )
      env = ENV.fetch("RAILS_ENV", DEFAULT_ENV)

      extract_database_paths(yaml.fetch(env, {}))
    end
  end

  def extract_database_paths(config)
    paths = []

    if config.is_a?(Hash)
      if config.key?("database")
        paths << config["database"]
      else
        config.each_value { |v| paths.concat(extract_database_paths(v)) }
      end
    end

    paths.select { |p| p.is_a?(String) && p.end_with?(".sqlite3") }
  end

  def source_files
    @source_files ||= database_paths.flat_map { |db|
      [ db, "#{db}-wal", "#{db}-shm" ].select { |f| File.exist?(f) }
    }
  end

  def checkpoint_wal_files
    @checkpointed = []
    database_paths.select { |db| File.exist?(db) }.each do |db|
      _stdout, stderr, status = Open3.capture3(
        "sqlite3", db, "PRAGMA wal_checkpoint(TRUNCATE);"
      )

      if status.success?
        @checkpointed << db
      elsif stderr.include?("database is locked") || stderr.include?("SQLITE_BUSY")
        warn "Warning: #{db} is locked — copy may include uncommitted WAL state. " \
             "Stop any running rails server/console and retry for a clean copy."
      else
        warn "Warning: checkpoint failed for #{db}: #{stderr.strip}"
      end
    end
  end

  def copy_databases
    @copied = []
    @backups = []

    if source_files.empty?
      puts "No SQLite3 database files found in main working tree — nothing to copy."
      puts "(This is normal for a fresh project that hasn't run migrations yet.)"
      return
    end

    target_storage = File.join(worktree_path, "storage")
    FileUtils.mkdir_p(target_storage)

    source_files.each do |file|
      destination = File.join(target_storage, File.basename(file))
      backup_if_exists(destination)
      FileUtils.cp(file, destination)
      @copied << destination
    end
  end

  def backup_if_exists(destination)
    return unless File.exist?(destination)

    backup_path = "#{destination}.bak"
    FileUtils.rm_f(backup_path)
    FileUtils.mv(destination, backup_path)
    @backups << backup_path
  end

  def print_summary
    puts ""
    @checkpointed.each { |db| puts "  Checkpointed: #{db}" } if @checkpointed&.any?
    puts "" if @checkpointed&.any?

    puts "Copied #{(@copied || []).size} file(s) to #{File.join(worktree_path, 'storage/')}"
    (@copied || []).each { |f| puts "  #{File.basename(f)}" }

    return unless (@backups || []).any?

    puts ""
    puts "Backed up #{@backups.size} existing file(s) before overwrite:"
    @backups.each { |f| puts "  #{f}" }
  end
end

exit SqliteWorktreePopulator.new(ARGV).call
