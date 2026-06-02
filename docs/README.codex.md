# Superpowers for Codex

Guide for using Superpowers with OpenAI Codex via the native plugin system or
legacy skill discovery.

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/lucianghinda/superpowers-ruby/refs/heads/main/.codex/INSTALL.md
```

## Plugin Installation

superpowers-ruby 7.0.0+ ships with a Codex plugin manifest. For new installs,
use Codex's plugin system:

```bash
codex plugin marketplace add lucianghinda/superpowers-ruby
codex plugin add superpowers-ruby@superpowers-ruby
```

If you previously added the marketplace and Codex says the plugin was not found,
refresh the marketplace snapshot and retry the add command:

```bash
codex plugin marketplace upgrade superpowers-ruby
codex plugin add superpowers-ruby@superpowers-ruby
```

Restart Codex after installing. Confirm the plugin is visible:

```bash
codex plugin list
```

To update later:

```bash
codex plugin marketplace upgrade superpowers-ruby
```

To uninstall:

```bash
codex plugin remove superpowers-ruby@superpowers-ruby
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
   git clone https://github.com/lucianghinda/superpowers-ruby.git ~/.codex/superpowers-ruby
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers-ruby/skills ~/.agents/skills/superpowers-ruby
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
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers-ruby" "$env:USERPROFILE\.codex\superpowers-ruby\skills"
```

## How It Works

The plugin install reads `.codex-plugin/plugin.json` and exposes the bundled
`skills/` directory to Codex.

The legacy install uses Codex's skill discovery directly. Codex scans
`~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on
demand. Superpowers skills are made visible through a single symlink:

```
~/.agents/skills/superpowers-ruby/ → ~/.codex/superpowers-ruby/skills/
```

The `using-superpowers` skill is discovered automatically and enforces skill usage discipline — no additional configuration needed.

## Usage

Skills are discovered automatically. Codex activates them when:
- You mention a skill by name (e.g., "use brainstorming")
- The task matches a skill's description
- The `using-superpowers` skill directs Codex to use one

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
codex plugin marketplace upgrade superpowers-ruby
```

For legacy symlink installs:

```bash
cd ~/.codex/superpowers-ruby && git pull
```

Skills update instantly through the symlink.

## Uninstalling

For plugin installs:

```bash
codex plugin remove superpowers-ruby@superpowers-ruby
codex plugin marketplace remove superpowers-ruby
```

For legacy symlink installs:

```bash
rm ~/.agents/skills/superpowers-ruby
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\superpowers-ruby"
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers-ruby` (Windows: `Remove-Item -Recurse -Force "$env:USERPROFILE\.codex\superpowers-ruby"`).

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/superpowers-ruby`
2. Check skills exist: `ls ~/.codex/superpowers-ruby/skills`
3. Restart Codex — skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/lucianghinda/superpowers-ruby/issues
- Main documentation: https://github.com/lucianghinda/superpowers-ruby
