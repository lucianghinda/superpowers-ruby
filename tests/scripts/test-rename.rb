#!/usr/bin/env ruby
# Offline regression checks for the RubyPowers rename and legacy project support.
require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'

ROOT = File.expand_path('../..', __dir__)

def check(condition, message)
  raise message unless condition
end

def run(*command, **options)
  output, status = Open3.capture2e(*command, **options)
  check(status.success?, "#{command.inspect} failed:\n#{output}")
  output
end

%w[legacy current mixed empty].each do |scenario|
  Dir.mktmpdir("rubypowers-#{scenario}-") do |project|
    run('git', 'init', '-q', project)
    directories = case scenario
    when 'legacy' then %w[superpowers]
    when 'current' then %w[rubypowers]
    when 'mixed' then %w[rubypowers superpowers]
    else []
    end
    expected = directories.flat_map do |name|
      %w[plans specs].map do |kind|
        relative = "docs/#{name}/#{kind}/example.md"
        FileUtils.mkdir_p(File.dirname(File.join(project, relative)))
        File.write(File.join(project, relative), "# Example\n")
        "- `#{relative}` (#{kind == 'plans' ? 'plan' : 'spec'})"
      end
    end
    handoff = run('bash', File.join(ROOT, 'hooks/handoff-create'), '--trigger', 'manual', chdir: project).strip
    content = File.read(handoff)
    expected.each { |entry| check(content.lines.count { |line| line.chomp == entry } == 1, "#{scenario}: missing or duplicate #{entry}") }
    check(content.include?('(no plan or spec files found)'), 'empty: missing placeholder') if expected.empty?
    puts "PASS: #{scenario} project handoff"
  end
end

platforms = {
  'Claude Code' => [{ 'CLAUDE_PLUGIN_ROOT' => ROOT }, %w[hookSpecificOutput additionalContext]],
  'Cursor' => [{ 'CURSOR_PLUGIN_ROOT' => ROOT }, %w[additional_context]],
  'Copilot' => [{ 'COPILOT_CLI' => '1' }, %w[additionalContext]]
}
platforms.each do |platform, (overrides, keys)|
  environment = { 'CLAUDE_PLUGIN_ROOT' => nil, 'CURSOR_PLUGIN_ROOT' => nil, 'COPILOT_CLI' => nil }.merge(overrides)
  context = JSON.parse(run(environment, 'bash', File.join(ROOT, 'hooks/session-start'))).dig(*keys)
  check(context&.include?('rubypowers:using-rubypowers'), "#{platform}: bootstrap must announce the renamed skill")
  check(context.include?('name: using-rubypowers'), "#{platform}: bootstrap must load the renamed skill content")
  check(!context.include?('Error reading'), "#{platform}: bootstrap failed to read its skill")
  puts "PASS: #{platform} bootstrap loads its skill"
end

install_doc = File.read(File.join(ROOT, '.codex/INSTALL.md'))
migration = install_doc[/### Migrating from old bootstrap\n(.*?)(?=\n### |\n## |\z)/m, 1]
check(migration, 'Codex install guide must document old-bootstrap migration')
link_commands = migration.scan(/```bash\n(.*?)```/m).flatten.find { |block| block.include?('ln -s') }
check(link_commands, 'Old-bootstrap migration must include an explicit symlink command')
Dir.mktmpdir('rubypowers-codex-migration-') do |home|
  old_skills = File.join(home, '.codex/superpowers-ruby/skills')
  FileUtils.mkdir_p(old_skills)
  File.write(File.join(old_skills, 'example.md'), 'existing skill')
  run('bash', '-eu', '-c', link_commands.gsub('~/', "#{home}/"))
  link = File.join(home, '.agents/skills/rubypowers')
  check(File.symlink?(link), 'Migration must create the new discovery symlink')
  check(File.read(File.join(link, 'example.md')) == 'existing skill', 'Migration must discover skills in the existing clone')
end
puts 'PASS: documented Codex migration discovers the existing clone'
