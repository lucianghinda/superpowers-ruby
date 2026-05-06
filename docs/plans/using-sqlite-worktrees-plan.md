# using-sqlite-worktrees — Implementation Plan

**Version:** 1.1
**Status:** Reviewed (engineering review — Scope Challenge + Test Review)
**Date:** 2026-04-18
**Mode:** New Feature (skill addition to `superpowers-ruby`)
**Revision note (1.1):** Applied findings F1–F8 from targeted engineering review. Added overwrite policy (F4), integration failure contract (F5), missing-database.yml test (F6), non-worktree-path test (F7), DB-locked scenario (F8), `sqlite3 .backup` design rationale (F3), tightened Unit 4 file list (F1), trimmed Unit 5 to smoke test (F2).

## Problem Frame

`superpowers-ruby/skills/using-git-worktrees` creates isolated workspaces but stops after `bundle install` + `bin/rails db:test:prepare`. For Rails 8 apps using SQLite (increasingly common since Rails 8 ships Solid Queue/Cache/Cable on SQLite by default), a fresh worktree has no development data — the developer must manually re-seed, re-migrate, or copy databases before meaningful work begins. Copying SQLite files naively also corrupts data: WAL-journal mode requires a `PRAGMA wal_checkpoint(TRUNCATE)` before the file copy, and the paired `-wal` / `-shm` sidecar files must travel together.

`postcraftstudio/bin/worktree` solves this for one project by shipping a Ruby script inside the Rails app. We want the same capability as a reusable Claude skill, auto-triggered when the target Rails app uses SQLite.

## Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| R1 | Skill auto-activates when target project has `config/database.yml` with SQLite adapter | Must Have | Via frontmatter `description:` signals |
| R2 | Skill parses multi-database `database.yml` (Solid Queue/Cache/Cable/errors) and collects all `.sqlite3` paths for `RAILS_ENV` (default `development`) | Must Have | Match `postcraftstudio` logic |
| R3 | Before copying, run `PRAGMA wal_checkpoint(TRUNCATE)` on each source DB | Must Have | Prevents partial-write corruption |
| R4 | Copy `.sqlite3`, `.sqlite3-wal`, `.sqlite3-shm` for each DB into worktree's `storage/` directory | Must Have | Sidecar files required for WAL consistency |
| R5 | Integrate with `using-git-worktrees` — that skill delegates to `using-sqlite-worktrees` after worktree creation and `bundle install`, before `bin/rails db:test:prepare` | Must Have | Clean separation of concerns |
| R6 | Helper Ruby script lives inside the skill folder (`skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb`); invoked via `${CLAUDE_PLUGIN_ROOT}` | Must Have | Hybrid delivery — no mutation of target project |
| R7 | Skill handles creation only; re-sync of stale worktrees is a one-liner in a "Re-syncing a stale worktree" section | Should Have | YAGNI — re-sync is rare |
| R8 | Skill fails loudly and safely when prerequisites are missing (no `config/database.yml`, no SQLite adapter, `sqlite3` CLI absent, source DB locked) | Must Have | Explicit error paths, not silent skips |
| R9 | Skill announces usage: "I'm using the using-sqlite-worktrees skill to set up SQLite databases in the worktree." | Should Have | Matches superpowers-ruby convention |
| R10 | Baseline pressure test documented in plan — confirm agent fails to copy SQLite correctly without the skill | Should Have | TDD-for-skills per `writing-skills` |

## Success Criteria

- From a Rails+SQLite project, invoking `using-git-worktrees` produces a worktree whose `storage/development*.sqlite3` files exist, are uncorrupted, and match the main working tree at time of creation.
- The target Rails project is **not modified** (no new files in its `bin/`, no commits created against it).
- `bin/rails console` in the new worktree can query existing dev data immediately without re-seeding.

## Scope Boundaries

**In scope:**
- Rails projects where `config/database.yml` uses `adapter: sqlite3`
- Single primary DB *and* Rails 8 multi-DB (Solid* trio) layouts
- WAL-mode SQLite (default in modern Rails)
- Creation flow only

**Out of scope:**
- Non-SQLite adapters (Postgres, MySQL) — they have their own provisioning needs
- Test DB seeding (stays with `bin/rails db:test:prepare`)
- Production DB handling (only `RAILS_ENV=development` by default)
- Re-sync of stale worktrees (documented one-liner only; no dedicated script)
- Databases stored outside the project tree (absolute paths)

## Key Decisions

| Decision | Chosen | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Skill name | `using-sqlite-worktrees` | Pairs semantically with `using-git-worktrees`; gerund convention | `rails-sqlite-worktrees`, `preparing-sqlite-worktree` |
| Delivery | Hybrid — script inside skill folder | Single source of truth; zero target-project mutation | Install scripts into target `bin/`; inline shell/ruby |
| Scope | Creation only + re-sync note | YAGNI; re-sync is infrequent and deliberate | Ship full creation + sync script pair |
| Integration style | `using-git-worktrees` explicitly delegates | Clean composition; avoids duplicating dir-selection/gitignore logic | Fold SQLite handling into `using-git-worktrees` directly |
| Ruby script source | Port `postcraftstudio/bin/worktree` minus the `git worktree add` wrapper | Battle-tested logic; the wrapper part belongs to `using-git-worktrees` | Rewrite from scratch |

## Outstanding Questions

| # | Question | Impact if Wrong | Owner |
|---|----------|-----------------|-------|
| Q1 | Does `${CLAUDE_PLUGIN_ROOT}` expand inside skill-invoked bash? | If not, must use a different path resolution (e.g., parse skill dir at runtime) | Verify during Unit 2 |
| Q2 | Should the script refuse to run if target worktree is not under the main repo's `.worktrees/` (safety against overwriting arbitrary dirs)? | Too strict = blocks valid flows; too loose = footgun | Deferred to Planning — default: accept any path, but require the path to already exist as a git worktree |

---

## Implementation Units

### Unit 1: Create `using-sqlite-worktrees` SKILL.md

**Goal:** Author the skill document that instructs Claude what to do, when to activate, and how to invoke the Ruby helper.

**Requirements trace:** R1, R7, R8, R9

**Dependencies:** None

**Files:**
- `skills/using-sqlite-worktrees/SKILL.md` — new file

**Approach:**
1. Frontmatter `description` must include distinctive auto-trigger signals: "Rails", "SQLite", "worktree", "development database", "copy databases". This is how Claude decides to invoke it.
2. Sections: Overview → When to Activate → Prerequisites Check → Invocation → Re-syncing a Stale Worktree → Red Flags → Integration.
3. The "When to Activate" section encodes the auto-trigger logic: called by `using-git-worktrees` *or* invoked directly when user says "copy my SQLite data into the worktree."
4. The "Prerequisites Check" section lists the four failure conditions from R8 and what to do for each.
5. "Invocation" shows the exact command: `ruby "${CLAUDE_PLUGIN_ROOT}/skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb" <worktree-path>`.
6. "Re-syncing a Stale Worktree" is 4–6 lines — the equivalent one-liner wrapping the same script against an existing worktree, with a warning about destructive overwrite.

**Patterns:**
- Mirror the structure of `using-git-worktrees/SKILL.md` (Overview, Process, Quick Reference, Common Mistakes, Red Flags, Integration)
- Use "Announce at start:" line per superpowers-ruby convention
- Use Red Flags "Never / Always" table at the end

**Test scenarios:**
- [ ] Happy path: Skill description matches a realistic query ("I want to work on a feature branch in isolation for this Rails app") → verified by baseline pressure test in Unit 5
- [ ] Nil/empty input: Skill invoked on a non-Rails project → Prerequisites Check catches it, exits cleanly
- [ ] Error path: `config/database.yml` present but uses Postgres → Prerequisites Check catches it
- [ ] Edge case: Skill invoked without `using-git-worktrees` having run first (worktree path doesn't exist) → Invocation section tells Claude to check path existence first

**Verification:** `cat skills/using-sqlite-worktrees/SKILL.md` shows valid frontmatter; description parses as YAML; document structure matches sibling skills; reading it end-to-end, another agent would know exactly when and how to use it.

**Planning-time unknowns:**
- Q1 (above) — `${CLAUDE_PLUGIN_ROOT}` availability. **Deferred to Planning.** If unavailable, fall back to documenting the relative path and letting the agent resolve it at runtime.

---

### Unit 2: Port the Ruby helper script

**Goal:** A standalone Ruby script that, given an existing worktree path, reads the main repo's `config/database.yml`, checkpoints each SQLite DB, and copies the DB + WAL + SHM files into the worktree's `storage/` directory.

**Requirements trace:** R2, R3, R4, R6, R8

**Dependencies:** None (can run in parallel with Unit 1)

**Files:**
- `skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb` — new file

**Approach:**
1. Start from `postcraftstudio/bin/worktree` (the `WorktreeCreator` class), but **remove the `git worktree add` wrapper** — that responsibility stays with `using-git-worktrees`.
2. New signature: `ruby create_sqlite_worktree.rb <worktree-path>` — single positional argument, the existing worktree directory.
3. Validate: path exists, path is a git worktree (run `git -C <path> rev-parse --is-inside-work-tree`), `config/database.yml` exists in main working dir (`Dir.pwd`).
4. Reuse the YAML parsing + `extract_database_paths` logic verbatim — that handles the multi-DB Solid* case cleanly.
5. Reuse `checkpoint_wal_files` verbatim. On `Errno::ENOENT` for the `sqlite3` CLI, abort with a clear install instruction (not `break` as postcraftstudio does).
6. Reuse `source_files` + `copy_databases` logic, targeting `<worktree-path>/storage/` instead of resolving from ARGV.
7. **Overwrite policy (F4):** Before overwriting any existing file in target `storage/`, rename it to `<filename>.bak`. If a `.bak` already exists, overwrite the `.bak` (one level of backup is enough). Print each backup path in the summary so the user can recover.
8. Print a structured summary on success; structured error + non-zero exit on failure.
9. Add frozen_string_literal magic comment; stick to stdlib only (no gems).
10. **Design note — why `cp` and not `sqlite3 .backup` (F3):** SQLite's native `.backup` command is atomic and doesn't require manual WAL checkpointing or sidecar-file copies. We use the `cp` + checkpoint approach because (a) it matches the proven `postcraftstudio` source, (b) worktree creation typically happens with no concurrent writer, and (c) it avoids shelling out to `sqlite3` for the copy itself (only for the checkpoint). Future maintainers considering a switch to `.backup` should weigh the atomicity win against the extra `sqlite3` process per DB. Document this tradeoff in a short comment at the top of the script.

**Patterns:**
- Follow postcraftstudio's class-based structure (`WorktreeCreator` equivalent, perhaps renamed `SqliteWorktreePopulator`)
- Use `Open3.capture3` for shell-outs (matches source)
- YAML safe_load with `permitted_classes: [Symbol], aliases: true` (matches source)

**Test scenarios:**
- [ ] Happy path: Single-DB Rails app, main has `storage/development.sqlite3` → worktree ends up with identical file
- [ ] Happy path: Multi-DB Rails 8 (Solid* trio) → all 5 dev DBs + their WAL/SHM files copied
- [ ] Nil/empty input: Worktree path doesn't exist → exit 1 with clear message
- [ ] Nil/empty input: No `.sqlite3` files found (fresh project, no migrations run yet) → exit 0 with informational message, not an error
- [ ] Nil/empty input: `config/database.yml` missing entirely (non-Rails dir) → exit 1 with "Is this a Rails project?" message **(F6)**
- [ ] Error path: `sqlite3` CLI not installed → exit 1 with install hint (brew/apt)
- [ ] Error path: Adapter in database.yml is postgres, not sqlite3 → exit 0 with "skipping, not a SQLite project"
- [ ] Error path: Target path exists but is not a git worktree (e.g., random dir) → `git -C <path> rev-parse --is-inside-work-tree` check fails → exit 1 with "not a git worktree" message **(F7)**
- [ ] Edge case: DB exists but no `-wal` / `-shm` sidecars (checkpointed cleanly, or not WAL mode) → copies just the main file, no error
- [ ] Edge case: Target worktree's `storage/development.sqlite3` already exists → existing file renamed to `development.sqlite3.bak` before overwrite; summary lists the backup path **(F4)**
- [ ] Edge case: Source DB locked by running `rails server` — `PRAGMA wal_checkpoint(TRUNCATE)` returns `SQLITE_BUSY` → script prints warning "DB locked, copy may include uncommitted WAL; consider stopping rails server", continues with copy. Document in skill's "Red Flags" that running server during copy is discouraged. **(F8)**

**Verification:**
```bash
# In a postcraftstudio-like clone with existing worktree
ruby skills/using-sqlite-worktrees/scripts/create_sqlite_worktree.rb /tmp/fake-worktree
diff main/storage/development.sqlite3 /tmp/fake-worktree/storage/development.sqlite3 # should match
```

**Planning-time unknowns:**
- How to signal "not-a-sqlite project" vs "actual error" to the calling skill? **Resolve in implementation.** Use exit code 0 for both success and skip-with-reason; exit code 1 only for genuine errors. Script prints reason to stdout.

---

### Unit 3: Integrate with `using-git-worktrees`

**Goal:** `using-git-worktrees` automatically delegates to `using-sqlite-worktrees` at the correct point in its workflow — after `bundle install`, before `bin/rails db:test:prepare`.

**Requirements trace:** R5

**Dependencies:** Units 1 + 2 (the delegated-to skill must exist)

**Files:**
- `skills/using-git-worktrees/SKILL.md` — modify Step 3 ("Run Project Setup")

**Approach:**
1. In Step 3, insert a new sub-step between `bundle install` and `bin/rails db:test:prepare`:
   ```
   # Rails + SQLite development database copy
   if [ -f Gemfile ] && [ -f config/database.yml ] && grep -q "adapter: sqlite3" config/database.yml; then
     # Delegate to using-sqlite-worktrees skill
   fi
   ```
2. Add a short paragraph above the bash block explaining the delegation: *"If the project uses SQLite, invoke the `using-sqlite-worktrees` skill to populate dev databases before preparing the test DB."*
3. Update the Quick Reference table to include a row for "Rails + SQLite project" → "Delegate to using-sqlite-worktrees".
4. Update the "Integration" section at the bottom — add `using-sqlite-worktrees` under "Pairs with".
5. Keep all existing behavior intact for non-SQLite projects.
6. **Failure contract (F5):** If the delegated `using-sqlite-worktrees` script exits non-zero, `using-git-worktrees` MUST (a) print the captured stderr, (b) skip `bin/rails db:test:prepare` (because the dev DB state is unknown — proceeding might mask the underlying issue), (c) skip the baseline test run, and (d) report the worktree as "created but DB setup incomplete — investigate sqlite-worktrees output before continuing." If the script exits 0, continue normally to `db:test:prepare`. Encode this contract explicitly in the SKILL.md step so future readers don't guess.

**Patterns:**
- Follow the existing Step 3 auto-detection style (`if [ -f X ]; then ...`)
- Match the existing doc's tone (concise, imperative, code-fenced commands)

**Test scenarios:**
- [ ] Happy path: Rails+SQLite project → delegation triggers, SQLite DBs copied, then `db:test:prepare` runs
- [ ] Non-trigger: Rails+Postgres project → delegation check fails on grep, flow continues directly to `db:test:prepare`
- [ ] Non-trigger: Non-Rails project (no Gemfile) → delegation check skipped entirely
- [ ] Edge case: Rails+SQLite project with no dev DB yet (fresh checkout, never migrated) → sqlite-worktrees skill runs, reports "no DBs to copy", flow continues without error
- [ ] Failure contract: sqlite-worktrees script exits 1 → using-git-worktrees prints stderr, skips `db:test:prepare` and baseline tests, reports worktree as "created but DB setup incomplete" **(F5)**

**Verification:** Read the updated `using-git-worktrees/SKILL.md` end-to-end as a fresh agent; confirm the delegation trigger, condition, and ordering are unambiguous and that the flow is reversible (non-SQLite path is untouched).

**Planning-time unknowns:** None.

---

### Unit 4: Update plugin manifests and CHANGELOG

**Goal:** The new skill is discoverable and documented at the plugin-surface level.

**Requirements trace:** (meta — supports R1 discoverability)

**Dependencies:** Units 1–3 (the skill must exist before being listed)

**Files (guaranteed vs. conditional — F1):**

*Guaranteed edits:*
- `CHANGELOG.md` — add entry under next unreleased version

*Conditional edits (edit only if inspection confirms enumeration exists):*
- `.claude-plugin/plugin.json` — inspect first; skills are likely auto-discovered by directory scan
- `.claude-plugin/marketplace.json` — inspect first
- `.cursor-plugin/plugin.json` — inspect first
- `README.md` — inspect first; edit only if it lists skills individually

**Approach:**
1. First, inspect each manifest: if skills are directory-scanned (most likely), no manifest changes needed. If explicitly listed, add the new skill entry.
2. CHANGELOG entry: *"Added `using-sqlite-worktrees` skill — auto-populates dev SQLite databases into new git worktrees for Rails projects. Integrates with `using-git-worktrees`."*
3. If user decides to bump plugin version, update all 6 files per the memory: `plugin.json` (x2), `marketplace.json`, `INSTALL.md`, `package.json`, `gemini-extension.json`. **Version bump is an explicit user decision, not automatic.**

**Patterns:**
- Match existing CHANGELOG entry voice and tense
- Don't bump version without explicit request

**Test scenarios:**
- [ ] Happy path: Manifests use directory scan → no edits required; only CHANGELOG entry added
- [ ] Alt path: Manifests enumerate skills → new skill appears in the list in correct alphabetical/insertion order
- [ ] Edge case: README doesn't list skills individually → skip README edit, note the decision

**Verification:** `git diff` after Unit 4 shows only CHANGELOG and (possibly) manifest additions; no unrelated churn; plugin loads in Claude Code without error.

**Planning-time unknowns:**
- Whether each manifest enumerates skills. **Resolve in implementation** by reading the files.

---

### Unit 5: Smoke test on a real Rails project

**Goal:** Confirm the end-to-end flow works on a real Rails+SQLite project, with data preserved across the worktree. Scope trimmed from full TDD cycle (F2) because this skill is invoked programmatically by `using-git-worktrees`, not by user-prompt judgment — rationalization risk is low.

**Requirements trace:** R10 (scope adjusted)

**Dependencies:** Units 1–4

**Files:** No code changes; optional short log at `docs/plans/using-sqlite-worktrees-smoke-test.md`.

**Approach:**
1. On a Rails+SQLite project (postcraftstudio or equivalent), invoke `using-git-worktrees` via Claude.
2. Verify delegation fires: `using-sqlite-worktrees` runs after `bundle install` and before `db:test:prepare`.
3. In the new worktree, run `bin/rails runner "puts SomeModel.count"` — count must match main.
4. Run one of the P1-adjacent scenarios manually to confirm the fix works: re-invoke the skill against the same worktree, verify the `.bak` backup appears as specified in F4.

**Patterns:**
- One real project beats many synthetic fixtures for smoke testing
- Capture output verbatim; if anything surprises you, fix it in the SKILL.md before shipping

**Test scenarios:**
- [ ] Happy path: Multi-DB (Solid*) Rails app → all 5 dev DBs present in worktree, record counts match
- [ ] Overwrite path: Re-invoke against same worktree → `.bak` backup files appear as specified
- [ ] Edge case: Fresh Rails project with no dev data → skill reports "nothing to copy", flow continues

**Verification:** Smoke test run succeeds end-to-end without manual intervention; `bin/rails runner` in worktree queries real data.

**Planning-time unknowns:**
- Which Rails fixture? **Resolve in implementation** — postcraftstudio is the known-good target.

---

## Quality Bar Checklist

- [x] Every unit has a requirements trace
- [x] Dependencies form a DAG (U1 ∥ U2 → U3 → U4 → U5; no cycles)
- [x] Every unit has at least 3 test scenarios (all units have 3+; Unit 2 has 7)
- [x] No unit touches >8 files (largest is Unit 4 at 5 files, and most are no-op inspections)
- [x] No more than 2 new abstractions per unit (Unit 2 introduces one Ruby class; others are doc edits)
- [x] Every planning-time unknown is classified (Q1 deferred, Q2 deferred, 3 unit-level unknowns all marked)
- [x] Handoff completeness: An engineer can execute this plan without inventing product behavior — every file path, script invocation, and integration point is spelled out.

## Execution Order

```
Unit 1 (SKILL.md)  ─┐
                    ├─→ Unit 3 (integrate) ─→ Unit 4 (manifests/CHANGELOG) ─→ Unit 5 (baseline test)
Unit 2 (Ruby script)┘
```

Units 1 and 2 are independent and can run in parallel.
