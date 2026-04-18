---
name: using-sqlite-worktrees
description: Use when creating a git worktree for a Rails project that uses SQLite - copies the main working tree's development SQLite databases (including Rails 8 Solid Queue/Cache/Cable) into the worktree's storage/ directory with proper WAL checkpointing, so the new worktree has real dev data without re-seeding or re-migrating
---

# Using SQLite Worktrees

## Overview

Rails projects on SQLite (especially Rails 8 with Solid Queue/Cache/Cable) keep their development data in `storage/*.sqlite3` files. When you create a new git worktree, that directory is empty — so `bin/rails console`, feature work, or spec runs against real data all fail until you re-migrate and re-seed. This skill copies the main working tree's SQLite files into the new worktree safely, handling WAL journal mode and Rails 8 multi-database layouts.

**Core principle:** Checkpoint before copy. Copy sidecars with the main file. Back up before overwrite.

**Announce at start:** "I'm using the using-sqlite-worktrees skill to copy SQLite development databases into the worktree."

## When to Activate

Activate in two situations:

1. **Delegated from `using-git-worktrees`** — that skill detects a Rails+SQLite project after running `bundle install` and delegates here before running `bin/rails db:test:prepare`.
2. **Invoked directly** — user says something like "copy my SQLite data into the worktree" or "refresh the worktree with current dev data."

Do NOT activate for:
- Non-Rails projects (no `config/database.yml`)
- Rails projects using Postgres, MySQL, or other non-SQLite adapters
- Production or test databases (this skill targets `RAILS_ENV=development` by default)

## Prerequisites Check

Before running the helper script, verify all four conditions. If any fail, stop and report — do not proceed with partial setup.

| Condition | Check | If Failing |
|-----------|-------|-----------|
| `config/database.yml` exists in main working dir | `test -f config/database.yml` | Report "Not a Rails project — skipping SQLite worktree setup" |
| Adapter is SQLite | `grep -q "adapter: sqlite3" config/database.yml` | Report "Not a SQLite project — skipping" |
| `sqlite3` CLI is installed | `command -v sqlite3` | Report "Install sqlite3 CLI (brew install sqlite3 / apt install sqlite3) and retry" |
| Target worktree path exists and is a git worktree | `git -C <path> rev-parse --is-inside-work-tree` | Report "Target path is not a git worktree — create it first via using-git-worktrees" |

## Invocation

From the main working directory (not the worktree), run the helper script:

```bash
ruby "${CLAUDE_PLUGIN_ROOT}/skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb" <worktree-path>
```

The script will:

1. Parse `config/database.yml` and collect all `.sqlite3` paths for `RAILS_ENV` (defaults to `development`)
2. Run `PRAGMA wal_checkpoint(TRUNCATE)` on each source database (flushes WAL into main file, safe to copy)
3. Back up any existing file in the target `storage/` as `<filename>.bak` before overwriting
4. Copy each `.sqlite3` file plus its `-wal` and `-shm` sidecars (if present) into `<worktree-path>/storage/`
5. Print a summary showing every file copied and every backup created

Exit codes:
- `0` — success, or a clean "nothing to do" (non-Rails / non-SQLite / no DB files yet)
- `1` — an actual error (missing CLI, invalid worktree path, database.yml parse failure, etc.)

## Re-syncing a Stale Worktree

If the main branch's dev data has moved forward and you want to refresh a worktree's `storage/`:

```bash
# Same script, same command. Existing worktree files get backed up as .bak before overwrite.
ruby "${CLAUDE_PLUGIN_ROOT}/skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb" <path-to-existing-worktree>
```

**Warning:** This overwrites the worktree's current dev DB. Any uncommitted data in the worktree's SQLite files is preserved as `<filename>.bak` but only one level of backup is kept — re-running again will overwrite `.bak` too. If the worktree has important local data, commit/export it first.

## Failure Contract with `using-git-worktrees`

When invoked via `using-git-worktrees` delegation:

- **Script exits 0** → `using-git-worktrees` continues normally to `bin/rails db:test:prepare` and the baseline test run.
- **Script exits non-zero** → `using-git-worktrees` MUST print the captured stderr, SKIP `bin/rails db:test:prepare`, SKIP baseline tests, and report the worktree as "created but DB setup incomplete — investigate output before continuing."

Never silently ignore a non-zero exit from this script.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Rails+SQLite worktree just created | Invoke the script against the worktree path |
| Rails+Postgres project | Do not activate — stay in `using-git-worktrees` flow |
| Non-Rails project | Do not activate |
| `sqlite3` CLI missing | Report install hint, do not proceed |
| Worktree path doesn't exist | Report error, ask to run `using-git-worktrees` first |
| Target `storage/` already populated | Script backs up existing as `.bak`, then copies — no manual action needed |
| Source DB locked by running `rails server` | Ask user to stop the server and retry; do not copy a locked DB |

## Red Flags

**Never:**
- Copy `.sqlite3` files with a raw `cp` without checkpointing WAL first — the copy will be inconsistent
- Copy the main `.sqlite3` file without also copying its `-wal` and `-shm` sidecars when they exist
- Overwrite a worktree's `storage/` without first backing up existing files
- Proceed past a non-zero exit code from the helper script
- Run the script while a `rails server` or `rails console` is actively writing to the source DB — stop the writer first

**Always:**
- Run prerequisites check before invoking the script
- Verify the worktree path is a genuine git worktree, not just any directory
- Pass the absolute or explicit path to the worktree as the single script argument
- Report the full summary output to the user (backups, files copied, skipped reasons)

## Common Mistakes

### Invoking from inside the worktree instead of main

**Problem:** The script reads `config/database.yml` from the current working directory (the source). If run from inside the worktree, it reads the worktree's own database.yml and tries to copy its own DBs onto itself.
**Fix:** Always `cd` to the main working directory before invoking.

### Trusting naive `cp` for SQLite files

**Problem:** SQLite in WAL mode keeps pending writes in `<db>-wal`. A plain `cp <db>` gives you a stale snapshot; the app sees a corrupted-looking state.
**Fix:** Use this skill's helper script, which runs `PRAGMA wal_checkpoint(TRUNCATE)` first and copies all three files.

### Skipping the git-worktree validation

**Problem:** If the user typos the target path, the script would happily create a `storage/` directory anywhere on disk.
**Fix:** The script guards with `git -C <path> rev-parse --is-inside-work-tree`. Do not bypass this guard.

## Integration

**Called by:**
- **using-git-worktrees** — REQUIRED delegation when Rails + SQLite detected, after `bundle install`, before `bin/rails db:test:prepare`

**Pairs with:**
- **using-git-worktrees** — owns worktree creation, gitignore checks, bundle install, test DB prep, baseline tests
- **finishing-a-development-branch** — cleanup workflow; does NOT need to touch SQLite files (worktree removal handles that)

## Example Workflow

```
Agent: I'm using the using-git-worktrees skill to set up an isolated workspace.
[Creates .worktrees/feature-x/ with git worktree add -b feature/x]
[Verifies .worktrees/ is in .gitignore]
[Runs bundle install in the worktree]
[Detects config/database.yml with adapter: sqlite3]

Agent: I'm using the using-sqlite-worktrees skill to copy SQLite development databases into the worktree.
[Runs ruby ${CLAUDE_PLUGIN_ROOT}/skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb .worktrees/feature-x]

Output:
  Checkpointed: storage/development.sqlite3
  Checkpointed: storage/development_cache.sqlite3
  Checkpointed: storage/development_queue.sqlite3
  Checkpointed: storage/development_cable.sqlite3
  Checkpointed: storage/development_errors.sqlite3

  Copied 5 SQLite3 database(s) to .worktrees/feature-x/storage/
    development.sqlite3
    development_cache.sqlite3
    development_queue.sqlite3
    development_cable.sqlite3
    development_errors.sqlite3

[Back to using-git-worktrees: runs bin/rails db:test:prepare]
[Runs bin/rails test — 124 passing]

Worktree ready at .worktrees/feature-x/
SQLite dev databases copied (5 DBs, 0 backups)
Tests passing (124 tests, 0 failures)
Ready to implement feature-x
```
