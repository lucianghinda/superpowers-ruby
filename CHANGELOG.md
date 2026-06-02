# Changelog

## [Unreleased]

## [7.1.0] - 2026-06-02

### Fixed

- **Codex install docs**: Corrected Codex's plugin command from `codex plugin install superpowers-ruby@superpowers-ruby` to `codex plugin add superpowers-ruby@superpowers-ruby`, and updated uninstall guidance to use `codex plugin remove`.
- **Codex marketplace discovery**: Added Codex's required `.agents/plugins/marketplace.json` index and a lightweight `plugins/superpowers-ruby` marketplace path so `codex plugin add superpowers-ruby@superpowers-ruby` can find the plugin after the marketplace is added or upgraded.

## [7.0.1] - 2026-05-27

### Added

- **ruby-upgrade skill**: Upgrades the Ruby *interpreter* version of a Bundler/Rails app, currently targeting the Ruby 3.x → 4.0.x jump. Runs a breaking-change risk audit via a single `Explore` subagent sweep, writes a stakeholder-ready analysis (`docs/ruby-upgrade/<date>/analysis.md`, falling back to `tmp/`), applies mechanical toolchain edits only where the old version was actually pinned (`.ruby-version`, Dockerfile, CI YAML, RuboCop `TargetRubyVersion`, Gemfile `cgi`/demoted-gem pins), then verifies with RuboCop, the test suite, and Sorbet/Tapioca when present. Ships a bundled breaking-change inventory (`references/ruby-4-0-changes.md`) verified against the upstream Ruby 4.0.0 release announcement: CGI session-class removal vs retained `cgi/escape`, `Net::HTTP` implicit Content-Type drop, demoted default gems, `Set` promoted to core + `Set#inspect` → `Set[...]`, `Ractor::Port` removals, `Kernel#open` pipe removal, `Process::Status` bitwise removal, OpenSSL 4, ZJIT (Rust 1.85.0+) vs YJIT. The description de-conflicts with `rails-upgrade` (interpreter version vs framework version) — verified by the skill-triggering test, which fires `ruby-upgrade` without collision.

## [7.0.0] - 2026-05-22

### Fixed

- **Copilot CLI compatibility**: The 6 skills that previously declared `name: superpowers-ruby:<slug>` in their frontmatter (`compound`, `compound-refresh`, `consulting-an-oracle`, `handoff`, `handoff-list`, `handoff-resume`) now use bare names (`name: <slug>`), matching the other 28 skills. Copilot CLI's name validator rejects `:` in the `name:` field with `Skill name must contain only letters, numbers, hyphens, underscores, dots, and spaces`, so those 6 skills failed to load. Bare names sidestep this because every loader auto-prepends `superpowers-ruby:` on display — any explicit prefix would double-prefix (`name: superpowers-ruby.handoff` would render as `/superpowers-ruby:superpowers-ruby.handoff` on Copilot). Supersedes [PR #12](https://github.com/lucianghinda/superpowers-ruby/pull/12), which proposed the same fix with hyphens and would have hit the same double-prefix issue.

### Added

- **Codex plugin manifest**: Added `.codex-plugin/plugin.json` so the repo installs via Codex's native plugin system (`codex plugin marketplace add lucianghinda/superpowers-ruby` + `codex plugin add superpowers-ruby@superpowers-ruby`). The legacy symlink install (clone + `ln -s …skills ~/.agents/skills/`) remains supported for users already on it; see `.codex/INSTALL.md` for both paths and the migration guide.

### Changed

- **Skill cross-references normalized**: A handful of skill bodies (`compound`, `compound-refresh`, `executing-plans`, `subagent-driven-development`, `systematic-debugging`, `writing-plans`, `writing-skills`, and others) referenced sibling skills as `superpowers:<slug>` (the OpenCode auto-prefix form, since the npm package is named `superpowers`). These references were normalized to `superpowers-ruby:<slug>` to match the catalog in `using-superpowers/SKILL.md` and the dominant convention used elsewhere in the repo. Picks up where the v6.0.0 namespace rename left off.

### Migration Guide

No action required for skill invocation — `/superpowers-ruby:handoff`, `/superpowers-ruby:compound`, etc. continue to work exactly as before. Codex users can optionally migrate from the legacy symlink install to the new plugin install (`rm ~/.agents/skills/superpowers-ruby` followed by the plugin install commands above); the symlink path remains supported indefinitely.

## [6.5.0] - 2026-05-06

### Added

- **consulting-an-oracle skill**: Packages a stalled in-session investigation into a self-contained oracle prompt at `tmp/oracle/<date>-<slug>.md` for a stronger one-shot model (GPT-5 Pro, Opus, Gemini Pro) to answer cold. Auto-detects Ruby/Rails project shape (Ruby version, framework, DB, test framework, jobs, asset pipeline, type tooling), pulls verbatim failure context and reconstructs hypothesis/action/outcome attempts from session history, walks one hop from the failing file (≤8 files / ≤2000 lines), and aggressively redacts secrets before write. The skill produces a file only — it does not call any model — keeping it model-agnostic and re-runnable. Includes a Ruby/Rails-specific suspect list (Zeitwerk autoloading, frozen string literals, thread safety, initializer order, gem version drift, monkey patches, environment differences) covering implicit context that an oracle cannot infer. Ships with three pressure tests and an academic comprehension test.

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
