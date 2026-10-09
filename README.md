# RubyPowers

A Ruby on Rails–focused fork of [obra/superpowers](https://github.com/obra/superpowers) — a complete software development workflow for coding agents built on composable "skills".

Known as **superpowers-ruby** before version **8.0.0**. Version 8.0.0 introduces
the RubyPowers product, plugin, and skill namespace. The GitHub repository is
also being renamed to `lucianghinda/rubypowers`; GitHub's redirect from the old
repository URL is expected after that rename is complete.

## Ruby/Rails Focus

This fork extends the core superpowers workflow with a full Ruby on Rails skills library:

- **Ruby language** idioms, modern features (3.x+), OOD philosophy
- **Rails testing** with Minitest and fixtures (no RSpec, no Capybara, no system tests)
- **Brakeman** security scanning
- **Sandi Metz rules** for maintainable OOP
- **Official Rails guides** indexed for quick reference
- **37signals/Basecamp patterns** derived from Fizzy codebase analysis
- **Hotwire** (Turbo + Stimulus) skills from Hotwire Club
- **Commit messages** following Conventional Commits with Ruby-specific body guidance

All examples, test commands, and file references use Ruby/Rails conventions throughout.

RubyPowers is a complete software development workflow for your coding agents, built on top of a set of composable "skills" and some initial instructions that make sure your agent uses them.


Here are the sources that I used to get the skills that are embeded here:
- https://github.com/el-feo/ai-context
- https://github.com/nateberkopec/dotfiles
- https://github.com/marckohlbrugge/unofficial-37signals-coding-style-guide
- https://github.com/rails/rails/tree/main/guides
- https://github.com/TheHotwireClub/hotwire_club-skills
- https://github.com/EveryInc/compound-engineering-plugin/tree/main/plugins/compound-engineering/skills/ce-compound

## How it works

It starts from the moment you fire up your coding agent. As soon as it sees that you're building something, it *doesn't* just jump into trying to write code. Instead, it steps back and asks you what you're really trying to do. 

Once it's teased a spec out of the conversation, it shows it to you in chunks short enough to actually read and digest. 

After you've signed off on the design, your agent puts together an implementation plan that's clear enough for an enthusiastic junior engineer with poor taste, no judgement, no project context, and an aversion to testing to follow. It emphasizes true red/green TDD, YAGNI (You Aren't Gonna Need It), and DRY. 

Next up, once you say "go", it launches a *subagent-driven-development* process, having agents work through each engineering task, inspecting and reviewing their work, and continuing forward. It's not uncommon for Claude to be able to work autonomously for a couple hours at a time without deviating from the plan you put together.

There's a bunch more to it, but that's the core of the system. And because the skills trigger automatically, you don't need to do anything special. Your coding agent just has RubyPowers.


## Sponsorship

If Superpowers has helped you do stuff that makes money and you are so inclined, I'd greatly appreciate it if you'd consider [sponsoring my Jesse's opensource work](https://github.com/sponsors/obra).

Thanks! 

- Jesse


## Installation

`rubypowers` ships as a **native plugin** for three platforms — **Codex**,
**Claude Code**, and **Copilot CLI** — using each platform's plugin marketplace.
A single repo with three platform-specific manifests
(`.codex-plugin/plugin.json`, `.claude-plugin/plugin.json`, and
`.cursor-plugin/plugin.json`), plus dedicated install paths for OpenCode and
Gemini CLI.

Quick reference:

| Platform | Install model | Install command |
|---|---|---|
| **Claude Code** | Native plugin | `/plugin marketplace add lucianghinda/rubypowers` then `/plugin install rubypowers@rubypowers` |
| **Codex** (8.0.0+) | Native plugin | `codex plugin marketplace add lucianghinda/rubypowers` then `codex plugin add rubypowers@rubypowers` |
| **GitHub Copilot CLI** | Native plugin | `copilot plugin marketplace add lucianghinda/rubypowers` then `copilot plugin install rubypowers@rubypowers` |
| **Cursor** | Local clone (no marketplace yet) | `cd ~/.cursor/plugins/local/ && git clone https://github.com/lucianghinda/rubypowers` |
| **OpenCode** | Agent-driven setup | See [`.opencode/INSTALL.md`](.opencode/INSTALL.md) |
| **Gemini CLI** | Extension | `gemini extensions install https://github.com/lucianghinda/rubypowers` |

Detailed instructions per platform follow below.

### Migrating from superpowers-ruby

Version 8.0.0 changes the plugin and skill namespace from `superpowers-ruby`
to `rubypowers`. Remove the old plugin and install RubyPowers using the command
for your platform. Existing projects keep using `docs/superpowers/` when that
folder already exists; new projects default to `docs/rubypowers/`. The skills
continue to read existing legacy plan and spec files.

| Platform | Remove old install | Install RubyPowers |
|---|---|---|
| Claude Code | `/plugin uninstall superpowers-ruby@superpowers-ruby` then `/plugin marketplace remove superpowers-ruby` | `/plugin marketplace add lucianghinda/rubypowers` then `/plugin install rubypowers@rubypowers` |
| Codex | `codex plugin remove superpowers-ruby@superpowers-ruby` | `codex plugin marketplace add lucianghinda/rubypowers` then `codex plugin add rubypowers@rubypowers` |
| GitHub Copilot CLI | `copilot plugin uninstall superpowers-ruby` | `copilot plugin marketplace add lucianghinda/rubypowers` then `copilot plugin install rubypowers@rubypowers` |
| Cursor | Remove the old local plugin directory | Clone `https://github.com/lucianghinda/rubypowers` into `~/.cursor/plugins/local/rubypowers` |
| OpenCode | Remove the `superpowers-ruby` plugin entry from `opencode.json` | Add `rubypowers@git+https://github.com/lucianghinda/rubypowers.git` to `opencode.json` |
| Gemini CLI | `gemini extensions uninstall superpowers-ruby` | `gemini extensions install https://github.com/lucianghinda/rubypowers` |

If the repository rename has not completed yet, use the new repository URL when
it becomes available; the old GitHub URL is expected to redirect only after
the rename.

Legacy Codex clone updates must use the path where the clone actually lives.
Pre-8.0.0 bootstrap installs remain at `~/.codex/superpowers-ruby`; new clones
use `~/.codex/rubypowers`. See [the Codex migration guide](.codex/INSTALL.md).

### Claude Code — Option 1: Install from GitHub

Register the marketplace, then install the plugin:

```bash
/plugin marketplace add lucianghinda/rubypowers
/plugin install rubypowers@rubypowers
```

### Claude Code — Option 2: Install from local clone

Clone the repository and install from the local directory:

```bash
git clone https://github.com/lucianghinda/rubypowers.git
/plugin install ./rubypowers
```

### Cursor 

Until the plugin is published on the cursor marketplace, use this command : 

```
cd ~/.cursor/plugins/local/ && git clone https://github.com/lucianghinda/rubypowers
```

### Codex

RubyPowers 8.0.0+ ships with a Codex plugin manifest, so it installs via Codex's
native plugin system:

```bash
codex plugin marketplace add lucianghinda/rubypowers
codex plugin add rubypowers@rubypowers
```

If you previously added the marketplace and Codex says the plugin was not found,
refresh the marketplace snapshot and retry the add command:

```bash
codex plugin marketplace upgrade rubypowers
codex plugin add rubypowers@rubypowers
```

A legacy symlink install (clone + `ln -s …skills ~/.agents/skills/`) is also
supported for users already on it. See [`.codex/INSTALL.md`](.codex/INSTALL.md)
for both paths and the migration guide.

**Detailed docs:** [docs/README.codex.md](docs/README.codex.md)

### OpenCode

Tell OpenCode:

```
Fetch and follow instructions from https://raw.githubusercontent.com/lucianghinda/rubypowers/refs/heads/main/.opencode/INSTALL.md
```

**Detailed docs:** [docs/README.opencode.md](docs/README.opencode.md)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add lucianghinda/rubypowers
copilot plugin install rubypowers@rubypowers
```

### Gemini CLI

```bash
gemini extensions install https://github.com/lucianghinda/rubypowers
```

See the [Updating](#updating) section below for update commands.

### Verify Installation

Start a new session in your chosen platform and ask for something that should trigger a skill (for example, "help me plan this feature" or "let's debug this issue"). The agent should automatically invoke the relevant RubyPowers skill.

## The Basic Workflow

1. **brainstorming** - Activates before writing code. Refines rough ideas through questions, explores alternatives, presents design in sections for validation. Saves design document.

2. **using-git-worktrees** - Activates after design approval. Creates isolated workspace on new branch, runs project setup, verifies clean test baseline.

3. **writing-plans** - Activates with approved design. Breaks work into bite-sized tasks (2-5 minutes each). Every task has exact file paths, complete code, verification steps.

4. **subagent-driven-development** or **executing-plans** - Activates with plan. Dispatches fresh subagent per task with two-stage review (spec compliance, then code quality), or executes in batches with human checkpoints.

5. **test-driven-development** - Activates during implementation. Enforces RED-GREEN-REFACTOR: write failing test, watch it fail, write minimal code, watch it pass, commit. Deletes code written before tests.

6. **requesting-code-review** - Activates between tasks. Reviews against plan, reports issues by severity. Critical issues block progress.

7. **finishing-a-development-branch** - Activates when tasks complete. Verifies tests, presents options (merge/PR/keep/discard), cleans up worktree.

**The agent checks for relevant skills before any task.** Mandatory workflows, not suggestions.

## What's Inside

### Skills Library

**Ruby/Rails**
- **ruby** - Ruby 3.x+ idioms, error handling, performance, OOD philosophy
- **brakeman** - Rails security static analysis
- **sandi-metz-rules** - OOP design rules for maintainable Ruby
- **rails-guides** - Official Rails documentation index (ActiveRecord, routing, controllers, views, jobs, mailers, Action Cable, etc.)
- **37signals-style** - 37signals/Basecamp Rails patterns (controllers, models, Hotwire, testing, etc.)
- **ruby-commit-message** - Conventional Commits for Rails projects with body written for junior developers
- **rails-upgrade** - Systematic Rails version upgrade workflow (5.2+) with live railsdiff.org diffs, breaking change detection, and gem compatibility checks
- **ruby-upgrade** - Ruby interpreter version upgrade workflow (3.x → 4.0.x) with breaking-change risk audit, mechanical toolchain edits (.ruby-version, Dockerfile, CI, RuboCop), and verification

**Hotwire / Turbo / Stimulus**
- **hwc-stimulus-fundamentals** - Stimulus controller lifecycle, values, targets, outlets
- **hwc-forms-validation** - Hotwire form workflows, inline editing, validation errors
- **hwc-navigation-content** - Turbo Frame pagination, tabbed navigation, lazy loading
- **hwc-realtime-streaming** - Turbo Streams over WebSocket/SSE, live updates
- **hwc-ux-feedback** - Loading states, optimistic UI, progress indicators
- **hwc-media-content** - Image/video/audio uploads, previews, playback

**Testing**
- **test-driven-development** - RED-GREEN-REFACTOR cycle with Ruby/Minitest examples (includes testing anti-patterns and Rails testing strategy)

**Debugging**
- **systematic-debugging** - 4-phase root cause process (includes root-cause-tracing, defense-in-depth, condition-based-waiting techniques)
- **verification-before-completion** - Ensure it's actually fixed

**Collaboration**
- **brainstorming** - Socratic design refinement
- **writing-plans** - Detailed implementation plans
- **executing-plans** - Batch execution with checkpoints
- **dispatching-parallel-agents** - Concurrent subagent workflows
- **requesting-code-review** - Pre-review checklist
- **receiving-code-review** - Responding to feedback
- **using-git-worktrees** - Parallel development branches
- **using-sqlite-worktrees** - Copies Rails SQLite development databases (incl. Solid Queue/Cache/Cable) into a new worktree, with WAL checkpointing and backup-before-overwrite
- **finishing-a-development-branch** - Merge/PR decision workflow
- **subagent-driven-development** - Fast iteration with two-stage review (spec compliance, then code quality)

**Meta**
- **writing-skills** - Create new skills following best practices (includes testing methodology)
- **using-rubypowers** - Introduction to the skills system

## Philosophy

- **Test-Driven Development** - Write tests first, always
- **Systematic over ad-hoc** - Process over guessing
- **Complexity reduction** - Simplicity as primary goal
- **Evidence over claims** - Verify before declaring success

Read more: [Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)

## Contributing

Skills live directly in this repository. To contribute:

1. Fork the repository
2. Create a branch for your skill
3. Follow the `writing-skills` skill for creating and testing new skills
4. If your change touches plugin manifests, skill frontmatter, or any
   cross-platform contract, smoke-test the branch on each affected platform
   before opening the PR — see
   [`docs/testing-plugin-installs.md`](docs/testing-plugin-installs.md)
   for per-platform install/verify/restore commands.
5. Submit a PR

See `skills/writing-skills/SKILL.md` for the complete guide on writing
skills, and [`docs/testing.md`](docs/testing.md) for running the
integration test suite.

## Updating

Skills update automatically when you update the plugin. Pick the command for
the platform you installed on.

### Claude Code

```bash
/plugin update rubypowers
```

### Codex

```bash
codex plugin marketplace upgrade rubypowers
```

If you're on the legacy symlink install (skills under `~/.agents/skills/`),
update by pulling the clone from the directory where it is installed. Use the
pre-8.0.0 path for an existing `superpowers-ruby` clone, or the RubyPowers path
for a new clone:

Pre-8.0.0 clone:
```bash
cd ~/.codex/superpowers-ruby && git pull
```

New clone:
```bash
cd ~/.codex/rubypowers && git pull
```

See [`.codex/INSTALL.md`](.codex/INSTALL.md) for migrating from symlink to
plugin.

### GitHub Copilot CLI

```bash
copilot plugin update rubypowers
```

### Cursor

Pull the latest in the plugin directory:

```bash
cd ~/.cursor/plugins/local/rubypowers && git pull
```

### OpenCode

Pull the latest in the install directory and restart OpenCode. See
[`.opencode/INSTALL.md`](.opencode/INSTALL.md) for the exact path on your
machine.

### Gemini CLI

```bash
gemini extensions update rubypowers
```

## License

MIT License - see LICENSE file for details

## Community

Superpowers is built by [Jesse Vincent](https://blog.fsck.com) and the rest of the folks at [Prime Radiant](https://primeradiant.com).

For community support, questions, and sharing what you're building with Superpowers, join us on [Discord](https://discord.gg/Jd8Vphy9jq).

## Support

- **Discord**: [Join us on Discord](https://discord.gg/Jd8Vphy9jq)
- **Issues**: https://github.com/lucianghinda/rubypowers/issues
