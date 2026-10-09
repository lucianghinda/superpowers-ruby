# Installing RubyPowers for Codex

Two install paths are supported. Prefer the **plugin install** for new setups
(version-pinned, official Codex plugin system). The **legacy symlink install**
remains supported for users already using it.

## Prerequisites

- Codex CLI with plugin support
- Git

## Migrating from superpowers-ruby 7.x

Version 8.0.0 changes the plugin name and skill prefix. Remove the old plugin,
then install the new marketplace entry:

```bash
codex plugin remove superpowers-ruby@superpowers-ruby
codex plugin marketplace add lucianghinda/rubypowers
codex plugin add rubypowers@rubypowers
```

If you used the legacy skill symlink, remove the old `superpowers-ruby` symlink
name as well. New legacy installs use `rubypowers`; for a pre-8.0.0 bootstrap
clone, use the migration instructions below and keep the existing clone path.

## Option 1 — Plugin install (recommended)

RubyPowers 8.0.0+ ships with a `.codex-plugin/plugin.json` manifest, so it can be
installed via Codex's native plugin system.

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

Restart Codex (quit and relaunch the CLI). Skills are discovered automatically.

To update later:

```bash
codex plugin marketplace upgrade rubypowers
```

To uninstall:

```bash
codex plugin remove rubypowers@rubypowers
```

## Option 2 — Legacy symlink install

Use this path if you prefer to keep skills under `~/.agents/skills/` without
going through Codex's plugin system, or if you're testing a local clone.

1. **Clone the RubyPowers repository:**
   ```bash
   git clone https://github.com/lucianghinda/rubypowers.git ~/.codex/rubypowers
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/rubypowers/skills ~/.agents/skills/rubypowers
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\rubypowers" "$env:USERPROFILE\.codex\rubypowers\skills"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

### Migrating from old bootstrap

If you installed superpowers-ruby before native skill discovery, keep using the
existing clone at `~/.codex/superpowers-ruby` and point the new skill namespace
at its `skills` directory. Do not move or reclone it for this migration.

Update the existing clone first:

```bash
cd ~/.codex/superpowers-ruby && git pull
```

Then remove the old symlink name if present and create the RubyPowers symlink:

```bash
rm ~/.agents/skills/superpowers-ruby 2>/dev/null || true
mkdir -p ~/.agents/skills
ln -s ~/.codex/superpowers-ruby/skills ~/.agents/skills/rubypowers
```

Remove the old `~/.agents/skills/superpowers-ruby` symlink if it exists, and
remove the old bootstrap block from `~/.codex/AGENTS.md` if it references
`superpowers-codex bootstrap`. Restart Codex after migration. For each later
update, run `git pull` in the actual clone path, which remains
`~/.codex/superpowers-ruby`:

```bash
cd ~/.codex/superpowers-ruby && git pull
```

Restart Codex after completing the migration.

### Updating

For a legacy clone install, always pull from the clone's actual directory. A
pre-8.0.0 clone remains at `~/.codex/superpowers-ruby`; a new clone may be at
`~/.codex/rubypowers`:

```bash
# Use the path that exists on your machine:
cd ~/.codex/superpowers-ruby && git pull
# Or, for a new clone:
cd ~/.codex/rubypowers && git pull
```

Skills update instantly through the symlink.

### Uninstalling

```bash
rm ~/.agents/skills/rubypowers
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers-ruby` for a pre-8.0.0 clone, or `rm -rf ~/.codex/rubypowers` for a new clone.

## Migrating from symlink to plugin

If you're currently on the legacy symlink install and want to switch to the
plugin install:

```bash
# Remove the legacy symlink (keep the clone if you want, but it's no longer used)
rm ~/.agents/skills/superpowers-ruby 2>/dev/null || true
rm ~/.agents/skills/rubypowers 2>/dev/null || true

# Install via Codex's plugin system
codex plugin marketplace add lucianghinda/rubypowers
codex plugin add rubypowers@rubypowers
```

Restart Codex to pick up the plugin install.

## Verify

After install, ask Codex to use one of the rubypowers skills (for
example, "use the brainstorming skill from rubypowers"). The plugin
install also surfaces in `codex plugin list`:

```bash
codex plugin list
```
