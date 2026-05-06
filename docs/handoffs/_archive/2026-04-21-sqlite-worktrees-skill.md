---
created: 2026-04-21T00:00:00Z
branch: lg/add-worktree-management-for-sqlite
trigger: manual
restored: true
restored_at: 2026-05-04T00:00:00Z
topic: sqlite-worktrees-skill
---

# Handoff: using-sqlite-worktrees skill

## Goal

Add a new skill to `superpowers-ruby` that auto-populates development SQLite databases (including Rails 8 Solid Queue/Cache/Cable multi-DB layouts) into a newly created git worktree, so a fresh worktree has real dev data without re-seeding or re-migrating. Inspired by `postcraftstudio/bin/worktree` — that project's Ruby script was the battle-tested source we ported. Integrates automatically with the existing `using-git-worktrees` skill.

## Current State

**Done:**
- Implementation plan written and committed (`e9c71e3`), revised after engineering review (`85e6ab0`)
- Skill `skills/using-sqlite-worktrees/` shipped with SKILL.md + Ruby helper script (`9b36180`)
- Integration with `using-git-worktrees` SKILL.md (auto-delegation after `bundle install`, before `db:test:prepare`)
- `CHANGELOG.md` updated under `[Unreleased]` (no version bump)
- `README.md` skill listing updated
- 4 of 5 smoke-test scenarios executed successfully (all validation/error paths)

**Deferred (not blocking merge, but worth doing before shipping):**
- Happy-path end-to-end smoke test in a real Rails+SQLite project — blocked by permission guard when the agent tried to create a test worktree in `postcraftstudio`. User must run this step manually.
- Version bump decision — plan left as `[Unreleased]`. If shipping as 6.4.0, need to update 6 files per user memory.

**Branch state:** 3 commits ahead of `main`, working tree clean.

## Key Decisions

- **Skill name: `using-sqlite-worktrees`** — rationale: pairs semantically with `using-git-worktrees` (gerund convention); alternatives considered: `rails-sqlite-worktrees`, `preparing-sqlite-worktree`
- **Delivery: hybrid (script inside skill folder, invoked via `${CLAUDE_PLUGIN_ROOT}`)** — rationale: single source of truth, zero mutation of target Rails project; alternatives rejected: install scripts into target `bin/` (invasive), inline shell/ruby (too complex for WAL handling)
- **Scope: creation only; re-sync documented as one-liner** — rationale: YAGNI; re-sync is infrequent and deliberate
- **WAL strategy: `cp` + `PRAGMA wal_checkpoint(TRUNCATE)`** — rationale: matches proven postcraftstudio source, worktree creation typically has no concurrent writer; `sqlite3 .backup` alternative documented in script header for future maintainers considering atomicity under concurrent writes
- **Overwrite policy: back up existing files as `*.bak` before overwrite** — rationale: silent overwrite = footgun if user re-runs or mistargets; backup is cheap
- **Integration failure contract: if sqlite script exits non-zero, `using-git-worktrees` halts setup, skips `db:test:prepare` and baseline tests, reports "DB setup incomplete"** — rationale: silent continue would leave worktree in unknown state
- **Auto-trigger mechanism: frontmatter `description:` keywords** — user wanted automatic activation; Claude reads descriptions to decide skill applicability, so signals like "Rails", "SQLite", "worktree", "copy databases" are in the description

## Modified Files

- `skills/using-sqlite-worktrees/SKILL.md` — new (165 lines)
- `skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb` — new (216 lines, executable)
- `skills/using-git-worktrees/SKILL.md` — modified (integration + failure contract)
- `CHANGELOG.md` — modified (`[Unreleased]` section added)
- `README.md` — modified (skill listing)
- `docs/plans/using-sqlite-worktrees-plan.md` — new (implementation plan, v1.1)

## Failed Approaches

- **Initial integration assumed cwd stayed in main working tree** — had to redesign after realizing `using-git-worktrees` Step 3 `cd`s into the new worktree before running `bundle install` and other setup. Fix: integration bash now captures `$(pwd)` as `WORKTREE_PATH`, then uses `git worktree list --porcelain | awk` to find the main working tree path, and invokes the Ruby script from a subshell `cd`'d there.
- **Tried to run happy-path smoke test by creating a git worktree in `postcraftstudio`** — blocked by the permission guard (correctly — `postcraftstudio` is an unrelated repo the user hadn't authorized for modification this session). Must be run manually by the user.

## Files to Read

- `docs/plans/using-sqlite-worktrees-plan.md` — full plan with 10 stable-ID requirements, 5 implementation units, quality-bar checklist, engineering review resolution
- `skills/using-sqlite-worktrees/SKILL.md` — skill doc with prerequisites check, invocation, failure contract, red flags, common mistakes, integration section
- `skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb` — Ruby helper; top comment explains the `cp` vs `sqlite3 .backup` design tradeoff
- `skills/using-git-worktrees/SKILL.md` — see the modified "Run Project Setup" step for the integration point and failure contract
- `CHANGELOG.md` — `[Unreleased]` section

## Next Steps

1. **Run the happy-path smoke test manually.** From `/Users/luciang/Dropbox/workprojects/explorations/postcraftsudio/apps/postcraftstudio`:
   ```bash
   git worktree add /tmp/pcs-smoke-test HEAD
   ruby /Users/luciang/Dropbox/workprojects/opensource/superpowers-ruby/skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb /tmp/pcs-smoke-test
   ls /tmp/pcs-smoke-test/storage/
   # Expect 5 *.sqlite3 files (development + cache + queue + cable + errors) plus any -wal/-shm sidecars
   git worktree remove /tmp/pcs-smoke-test --force
   ```
2. **Verify the end-to-end integration via Claude** — open a fresh Claude Code session in `postcraftstudio`, ask it to create a worktree; confirm `using-git-worktrees` auto-delegates to `using-sqlite-worktrees` and the new worktree's `bin/rails console` can query existing dev data.
3. **Decide on version bump.** If shipping as 6.4.0, update 6 files per user memory: `.claude-plugin/plugin.json`, `.cursor-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `INSTALL.md`, `package.json`, `gemini-extension.json`. Move `CHANGELOG.md` `[Unreleased]` section to `[6.4.0] - 2026-04-21`.
4. **Open PR to `lucianghinda/superpowers-ruby`** (per user memory: NEVER to `obra/superpowers`).
5. **Optional follow-up:** If the happy-path test reveals the `cp` approach has problems under any concurrency, switch the script to `sqlite3 <db> ".backup <target>"` — the design note at the top of the Ruby script explains the tradeoff.

## Open Questions

- **Version bump timing** — user hasn't decided whether to ship as 6.4.0 or include additional changes in the same release. Current state (`[Unreleased]`) is safe either way.
- **Should `using-sqlite-worktrees` also handle non-default `RAILS_ENV`?** — Currently defaults to `development` via `ENV.fetch("RAILS_ENV", "development")`. If someone wants to copy `staging` or `integration` env DBs, it'll work by setting `RAILS_ENV` before invocation — but this isn't tested and isn't documented in the SKILL.md. Low-priority; most worktree use cases are dev-only.
- **Should the re-sync one-liner be promoted to its own skill entry point** (e.g., `using-sqlite-worktrees:resync`)? — Currently just documented in SKILL.md. Revisit if users hit this scenario frequently.
