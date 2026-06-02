# Installing Superpowers for Codex

Two install paths are supported. Prefer the **plugin install** for new setups
(version-pinned, official Codex plugin system). The **legacy symlink install**
remains supported for users already using it.

## Prerequisites

- Codex CLI with plugin support
- Git

## Option 1 — Plugin install (recommended)

superpowers-ruby 7.0.0+ ships with a `.codex-plugin/plugin.json` manifest, so it can be
installed via Codex's native plugin system.

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

Restart Codex (quit and relaunch the CLI). Skills are discovered automatically.

To update later:

```bash
codex plugin marketplace upgrade superpowers-ruby
```

To uninstall:

```bash
codex plugin remove superpowers-ruby@superpowers-ruby
```

## Option 2 — Legacy symlink install

Use this path if you prefer to keep skills under `~/.agents/skills/` without
going through Codex's plugin system, or if you're testing a local clone.

1. **Clone the superpowers repository:**
   ```bash
   git clone https://github.com/lucianghinda/superpowers-ruby.git ~/.codex/superpowers-ruby
   ```

2. **Create the skills symlink:**
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers-ruby/skills ~/.agents/skills/superpowers-ruby
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers-ruby" "$env:USERPROFILE\.codex\superpowers-ruby\skills"
   ```

3. **Restart Codex** (quit and relaunch the CLI) to discover the skills.

### Migrating from old bootstrap

If you installed superpowers before native skill discovery, you need to:

1. **Update the repo:**
   ```bash
   cd ~/.codex/superpowers-ruby && git pull
   ```

2. **Create the skills symlink** (step 2 above) — this is the new discovery mechanism.

3. **Remove the old bootstrap block** from `~/.codex/AGENTS.md` — any block referencing `superpowers-codex bootstrap` is no longer needed.

4. **Restart Codex.**

### Updating

```bash
cd ~/.codex/superpowers-ruby && git pull
```

Skills update instantly through the symlink.

### Uninstalling

```bash
rm ~/.agents/skills/superpowers-ruby
```

Optionally delete the clone: `rm -rf ~/.codex/superpowers-ruby`.

## Migrating from symlink to plugin

If you're currently on the legacy symlink install and want to switch to the
plugin install:

```bash
# Remove the legacy symlink (keep the clone if you want, but it's no longer used)
rm ~/.agents/skills/superpowers-ruby

# Install via Codex's plugin system
codex plugin marketplace add lucianghinda/superpowers-ruby
codex plugin add superpowers-ruby@superpowers-ruby
```

Restart Codex to pick up the plugin install.

## Verify

After install, ask Codex to use one of the superpowers-ruby skills (for
example, "use the brainstorming skill from superpowers-ruby"). The plugin
install also surfaces in `codex plugin list`:

```bash
codex plugin list
```
