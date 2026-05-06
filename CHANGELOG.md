# Changelog

## [Unreleased]

## [6.4.0] - 2026-05-04

### Added

- **using-sqlite-worktrees skill**: Copies Rails development SQLite databases (including Rails 8 Solid Queue/Cache/Cable multi-DB layouts) into a new git worktree's `storage/` directory. Handles WAL journal mode via `PRAGMA wal_checkpoint(TRUNCATE)` before copy and includes `-wal`/`-shm` sidecar files. Backs up existing files as `*.bak` before overwrite. Ruby helper script ships inside the skill folder, invoked via `${CLAUDE_PLUGIN_ROOT}`.
- **using-git-worktrees integration**: Auto-delegates to `using-sqlite-worktrees` when a Rails project uses SQLite. Delegation runs after `bundle install` and before `bin/rails db:test:prepare`. If the delegated script fails, `using-git-worktrees` halts setup and reports "DB setup incomplete" rather than silently continuing.

## [6.3.0] - 2026-04-14

### Added

- **handoff skill**: Captures session state (goals, decisions, modified files, failed approaches, next steps) to `docs/handoffs/` so future sessions or different agents can resume seamlessly. Three commands: `superpowers-ruby:handoff` (create), `superpowers-ruby:handoff-resume` (restore), `superpowers-ruby:handoff-list` (browse).
- **Automatic compaction handoff**: `PreCompact`/`PostCompact` hooks (Claude Code) and `experimental.session.compacting`/`session.compacted` events (OpenCode) capture and restore handoff documents automatically around context compaction. Codex gets manual-only support.
- **Cross-agent handoff**: Handoff documents are plain markdown with YAML frontmatter, readable by any agent or tool. Supports Claude Code → OpenCode, agent → human, human → agent, and subagent → parent handoff scenarios.

## [6.2.0] - 2026-04-03

### Changed

- **brainstorming**: Replaced Spec Review Loop (subagent dispatch + 3-iteration cap) with inline Spec Self-Review checklist: placeholder scan, internal consistency, scope check, ambiguity check. Eliminates a brittle multi-agent loop that doubled execution time.
- **writing-plans**: Replaced Plan Review Loop with inline Self-Review checklist: spec coverage, placeholder scan, type consistency. Added explicit "No Placeholders" section defining plan failures (TBD, vague descriptions, undefined references, "similar to Task N").

### Added

- **GitHub Copilot CLI support**: SessionStart hook detects `COPILOT_CLI` environment variable and emits SDK-standard `{ "additionalContext": "..." }` format. Added `references/copilot-tools.md` with full Claude Code → Copilot CLI tool equivalence table.
- **codex-tools**: Added named agent dispatch mapping documenting how to translate Claude Code's named agent types to Codex's `spawn_agent` with worker roles.

## [6.1.0] - 2026-03-30

### Added

- **rails-upgrade skill**: New self-contained skill for upgrading Rails applications (5.2 through 8.1). Merges the best of [OmbuLabs/FastRuby.io](https://github.com/ombulabs/claude-code_rails-upgrade-skill) and [Mario Alberto Chávez Cárdenas](https://github.com/mariochavez/rails-upgrade-skill) (both MIT). Features direct Grep/Glob/Read detection (no script round-trip), live config diffs via the railsdiff.org GitHub API, 3 hard gates (test baseline, load_defaults verification, user approval), and 7 reference files covering breaking changes, deprecation timeline, gem compatibility, load_defaults guide, detection patterns, dual-boot setup, and troubleshooting. Includes `scripts/fetch-changelogs.sh` to pull component CHANGELOGs from GitHub for any Rails version. ([PR #7](https://github.com/lucianghinda/superpowers-ruby/pull/7))

## [6.0.1] - 2026-03-30

### Changed

- **writing-skills**: Document all agentskills.io frontmatter fields (`license`, `compatibility`, `metadata`, `allowed-tools`) — previously only `name` and `description` were documented

## [6.0.0] - 2026-03-27

### Changed

- **Skill namespace rename**: All skill names now use `superpowers-ruby:` prefix instead of `superpowers:` to match the plugin name
- **Skill directory rename**: `skills/superpowers-compound/` → `skills/compound/`, `skills/superpowers-compound-refresh/` → `skills/compound-refresh/`
- **Session-start hook**: Updated context message to reference "superpowers for Ruby and Rails" and the `superpowers-ruby:using-superpowers` skill name

### Added

- **Skills Catalog**: Added a complete skills catalog table to the `using-superpowers` skill, organized by category (Process & Workflow, Ruby & Rails, Hotwire & Stimulus, Security, Code Review, Meta) so Claude always has the full skill index in context

### Migration Guide

**Uninstall and reinstall the plugin** to pick up the renamed skill directories and namespace changes:

```bash
# Claude Code
claude plugin uninstall superpowers-ruby@superpowers-ruby
claude plugin install superpowers-ruby@superpowers-ruby

# Or re-run the installer
```

If you were using `superpowers:compound` or `superpowers:compound-refresh` by name anywhere (custom hooks, CLAUDE.md, scripts), update those references to `superpowers-ruby:compound` and `superpowers-ruby:compound-refresh`.

## [5.0.6] - 2026-03-24

### Added

- **ruby-commit-message skill**: New skill for writing idiomatic Ruby-style git commit messages. Covers tense, length limits, subject/body separation, and Ruby/Rails-specific conventions for referencing classes, methods, and modules. ([PR #1](https://github.com/lucianghinda/superpowers-ruby/pull/1))
- **superpowers:compound skill**: Captures freshly solved problems into structured `docs/solutions/` learning docs using parallel subagents. Ported from [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin), adapted to superpowers-ruby conventions: `name`/`description`-only frontmatter, CSO-compliant trigger-first description, compressed from 1901 to 690 words. ([PR #2](https://github.com/lucianghinda/superpowers-ruby/pull/2))
- **superpowers:compound-refresh skill**: Maintains `docs/solutions/` accuracy over time. Supports interactive and autonomous (`mode:autonomous`) modes. Four maintenance outcomes: Keep, Update, Replace, Archive. Includes Common Mistakes section covering Update/Replace confusion, Archive vs Replace with active problem domains, and autonomous report completeness. ([PR #2](https://github.com/lucianghinda/superpowers-ruby/pull/2))

### Improved

- **ruby skill — CSO description**: Rewrote description to be trigger-first (`Use when...`) instead of leading with a content summary. Added `raise vs fail` and `memoization` as keywords so the skill surfaces for the exact questions it uniquely answers. ([PR #3](https://github.com/lucianghinda/superpowers-ruby/pull/3))
- **ruby skill — Overview section**: Added 2-sentence overview clarifying the skill covers patterns agents miss by default — the Weirich raise/fail distinction, nil-safe memoization, result objects, and performance-conscious enumeration. ([PR #3](https://github.com/lucianghinda/superpowers-ruby/pull/3))
- **ruby skill — Common Mistakes table**: Added 6-entry table covering `raise` vs `fail`, `||=` nil caveat, `+=` vs `<<`, `rescue Exception`, deep `&.` chains, and missing `frozen_string_literal`. ([PR #3](https://github.com/lucianghinda/superpowers-ruby/pull/3))

### Tests

- Added skill-triggering test for `compound`: naive N+1 query scenario confirms the skill triggers from a natural prompt.
- Added explicit-skill-request test for `compound-refresh`: user-named invocation test (`disable-model-invocation: true` makes auto-triggering intentionally unavailable).
- Added skill-triggering test for `ruby`: `raise` vs `fail` question — confirmed by subagent testing to discriminate skill-loaded vs memory-only answers.

## [5.0.5] - 2026-03-17

### Fixed

- **Brainstorm server ESM fix**: Renamed `server.js` → `server.cjs` so the brainstorming server starts correctly on Node.js 22+ where the root `package.json` `"type": "module"` caused `require()` to fail. ([PR #784](https://github.com/obra/superpowers/pull/784) by @sarbojitrana, fixes [#774](https://github.com/obra/superpowers/issues/774), [#780](https://github.com/obra/superpowers/issues/780), [#783](https://github.com/obra/superpowers/issues/783))
- **Brainstorm owner-PID on Windows**: Skip `BRAINSTORM_OWNER_PID` lifecycle monitoring on Windows/MSYS2 where the PID namespace is invisible to Node.js. Prevents the server from self-terminating after 60 seconds. The 30-minute idle timeout remains as the safety net. ([#770](https://github.com/obra/superpowers/issues/770), docs from [PR #768](https://github.com/obra/superpowers/pull/768) by @lucasyhzhu-debug)
- **stop-server.sh reliability**: Verify the server process actually died before reporting success. Waits up to 2 seconds for graceful shutdown, escalates to `SIGKILL`, and reports failure if the process survives. ([#723](https://github.com/obra/superpowers/issues/723))

### Changed

- **Execution handoff**: Restore user choice between subagent-driven-development and executing-plans after plan writing. Subagent-driven is recommended but no longer mandatory. (Reverts `5e51c3e`)
