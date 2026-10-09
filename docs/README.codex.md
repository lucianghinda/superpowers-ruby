# RubyPowers for Codex

Guide for using RubyPowers with OpenAI Codex via the native plugin system or
legacy skill discovery.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/lucianghinda/rubypowers/refs/heads/main/.codex/INSTALL.md
```

## Migrating from superpowers-ruby

Version 8.0.0 changes the plugin name and skill prefix from `superpowers-ruby`
to `rubypowers`. Remove the old plugin before installing the new one:

```bash
codex plugin remove superpowers-ruby@superpowers-ruby
codex plugin marketplace add lucianghinda/rubypowers
codex plugin add rubypowers@rubypowers
```

If you installed through the old bootstrap, retain the existing
`~/.codex/superpowers-ruby` clone and follow the old-bootstrap migration in
[`.codex/INSTALL.md`](../.codex/INSTALL.md). New projects use `docs/rubypowers/`;
existing projects with `docs/superpowers/` keep that folder and its documents.

## Plugin Installation

RubyPowers 8.0.0+ ships with a Codex plugin manifest. For new installs,
use Codex's plugin system:

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

Restart Codex after installing. Confirm the plugin is visible:

```bash
codex plugin list
```

To update later:

```bash
codex plugin marketplace upgrade rubypowers
```

To uninstall:

```bash
codex plugin remove rubypowers@rubypowers
```

## Legacy Symlink Installation

### Prerequisites

- OpenAI Codex CLI
- Git

Use this path if you prefer to keep skills under `~/.agents/skills/` without
going through Codex's plugin system, or if you're testing a local clone.

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/lucianghinda/rubypowers.git ~/.codex/rubypowers
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/rubypowers/skills ~/.agents/skills/rubypowers
   ```

3. Restart Codex.

4. **For subagent skills** (optional): Skills like `dispatching-parallel-agents` and `subagent-driven-development` require Codex's multi-agent feature. Add to your Codex config:
   ```toml
   [features]
   multi_agent = true
   ```

### Windows

Use a junction instead of a symlink (works without Developer Mode):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\rubypowers" "$env:USERPROFILE\.codex\rubypowers\skills"
```

## How It Works

The plugin install reads `.codex-plugin/plugin.json` and exposes the bundled
`skills/` directory to Codex.

The legacy install uses Codex's skill discovery directly. Codex scans
`~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on
demand. RubyPowers skills are made visible through a single symlink:

```
~/.agents/skills/rubypowers/ → ~/.codex/rubypowers/skills/
```

The `using-rubypowers` skill is discovered automatically and enforces skill usage discipline — no additional configuration needed.

## Usage

Skills are discovered automatically. Codex activates them when:
- You mention a skill by name (e.g., "use brainstorming")
- The task matches a skill's description
- The `using-rubypowers` skill directs Codex to use one

### Personal Skills

Create your own skills in `~/.agents/skills/`:

```bash
mkdir -p ~/.agents/skills/my-skill
```

Create `~/.agents/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

The `description` field is how Codex decides when to activate a skill automatically — write it as a clear trigger condition.

## Updating

For plugin installs:

```bash
codex plugin marketplace upgrade rubypowers
```

For legacy symlink installs, always pull from the clone's actual directory.
Choose the command matching your clone:

Pre-8.0.0 clone:
```bash
cd ~/.codex/superpowers-ruby && git pull
```

New clone:
```bash
cd ~/.codex/rubypowers && git pull
```

Skills update instantly through the symlink.

## Uninstalling

For plugin installs:

```bash
codex plugin remove rubypowers@rubypowers
codex plugin marketplace remove rubypowers
```

For legacy symlink installs:

```bash
rm ~/.agents/skills/superpowers-ruby 2>/dev/null || true
rm ~/.agents/skills/rubypowers 2>/dev/null || true
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\rubypowers"
```

Optionally delete the clone after removing its symlink: `rm -rf ~/.codex/superpowers-ruby` for an older clone, or the actual directory used by a newer install.

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/rubypowers`
2. Check skills exist: `ls ~/.codex/rubypowers/skills`
3. Restart Codex — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/lucianghinda/rubypowers/issues
- Main documentation: https://github.com/lucianghinda/rubypowers
