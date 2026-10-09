# Testing Plugin Installs Across Platforms

How to manually smoke-test a `rubypowers` branch on each supported
platform. Use this when you have an unmerged branch (or a release candidate)
and want to verify it loads and runs correctly before merging.

This is **manual smoke testing**, not integration testing. For automated
integration tests that exercise skills with real Claude sessions, see
[`testing.md`](./testing.md).

## When to use this

- After making changes to skill frontmatter, plugin manifests, or any
  cross-platform contract (skill names, hook scripts, install instructions).
- Before tagging a release.
- After receiving a contributor PR that touches install paths.
- When debugging a "skill not loading" report on a specific platform.

## Setup

Define these once in your shell so the commands below stay copy-pasteable:

```bash
# Path to your local clone of rubypowers (the working tree)
LOCAL_PATH="/Users/lucianghinda/Dropbox/workprojects/opensource/rubypowers"

# Branch name to test (use `main` for release-candidate testing)
BRANCH="lg/rename-compatibility"

# GitHub repo (owner/name)
REPO="lucianghinda/rubypowers"
```

## What you're testing

Each install path produces a different artifact on disk. Knowing where to
look helps confirm the install actually picked up your branch:

| Platform | Install artifact location |
|---|---|
| Claude Code | `~/.claude/plugins/cache/<marketplace>/rubypowers/<version>/` |
| Codex | `~/.codex/plugins/cache/<marketplace>/rubypowers/<version>/` |
| Copilot CLI | `~/.copilot/installed-plugins/_direct/rubypowers/` (for direct installs) |
| OpenCode | `~/.config/opencode/plugins/rubypowers.js` (symlink to install location) |

The `_direct/` segment in Copilot's path is its marker for "installed from a
non-marketplace source" — useful to confirm a local-path install did what you
expected.

---

## 1. Claude Code

### Test from local clone (recommended for branch testing)

Claude Code's `/plugin install` from GitHub fetches the default branch only.
Local-clone install is the reliable path for testing arbitrary branches.

```bash
# 1. Remove the marketplace-installed copy
/plugin uninstall rubypowers@rubypowers

# 2. Install from the working tree (pass the absolute path)
/plugin install $LOCAL_PATH

# 3. Reload (or quit + relaunch Claude Code)
/reload-plugins
```

### Verify

- `/plugin` lists `rubypowers` as installed.
- The skills list shows each skill exactly **once**, with `rubypowers:`
  as the prefix and no `rubypowers:rubypowers:<x>` double-prefix.
- Try invoking one of the renamed skills directly: `/rubypowers:handoff`
  should run the skill, not error.

### Restore the marketplace install

```bash
/plugin uninstall rubypowers@rubypowers
/plugin marketplace add lucianghinda/rubypowers
/plugin install rubypowers@rubypowers
```

---

## 2. Copilot CLI

### Test from local path (proven, simplest)

```bash
# 1. Remove the existing direct-install (if any)
copilot plugin uninstall rubypowers

# 2. Install from the working tree
copilot plugin install "$LOCAL_PATH"

# 3. Confirm
copilot plugin list
```

### Test from GitHub branch

Copilot's `plugin install` doesn't expose a `--ref` flag, so the most
reliable branch-aware install is to clone the branch first then install
from the clone:

```bash
# Clone the branch into a temp dir
git clone --branch "$BRANCH" "https://github.com/$REPO.git" /tmp/rubypowers-test

copilot plugin uninstall rubypowers
copilot plugin install /tmp/rubypowers-test
```

### Verify

In a Copilot session, type `/` and look at the slash-command list:

- The skills appear as `/rubypowers:<slug>` with a **single** prefix
  (not `/rubypowers:rubypowers.<slug>` or similar).
- No `Skill name must contain only letters, numbers, hyphens, underscores,
  dots, and spaces` errors are emitted at install time.
- All previously-failing skills (`compound`, `compound-refresh`,
  `consulting-an-oracle`, `handoff`, `handoff-list`, `handoff-resume`)
  appear in the slash-command list and are invokable.

### Restore the marketplace install

```bash
copilot plugin uninstall rubypowers
copilot plugin marketplace add lucianghinda/rubypowers
copilot plugin install rubypowers@rubypowers

# If you used the /tmp clone, clean it up
rm -rf /tmp/rubypowers-test
```

---

## 3. Codex

rubypowers 7.0.0+ supports a native Codex plugin install. The legacy symlink-based
install (`~/.agents/skills/rubypowers` → clone) remains supported.

### Test from local working tree (legacy symlink path — simplest)

```bash
# 1. Save the current symlink target so you can restore it
readlink ~/.agents/skills/rubypowers
# Example output: /Users/<you>/.codex/rubypowers/skills

# 2. Re-point at the working tree
rm ~/.agents/skills/rubypowers
ln -s "$LOCAL_PATH/skills" ~/.agents/skills/rubypowers

# 3. Restart Codex (quit and relaunch the CLI)
```

### Test from GitHub branch via the new Codex plugin install

```bash
# 1. Remove the legacy symlink so it doesn't shadow the plugin install
rm ~/.agents/skills/rubypowers

# 2. Add the marketplace entry pointing at the branch
codex plugin marketplace add "$REPO" --ref "$BRANCH"

# 3. Install
codex plugin add rubypowers@rubypowers

# 4. Confirm install location matches expectation
codex plugin list
ls ~/.codex/plugins/cache/rubypowers/rubypowers/

# 5. Restart Codex
```

### Verify

- For the **symlink path**: `~/.agents/skills/rubypowers/` should
  contain all 34 skill subdirectories.
- For the **plugin path**: `codex plugin list` shows
  `rubypowers@<version>`.
- In a Codex session, ask: "use the handoff skill from rubypowers" —
  it should find and run the skill.

### Restore afterwards

If you used the **symlink path**, restore the original symlink target:

```bash
rm ~/.agents/skills/rubypowers
ln -s /Users/<you>/.codex/rubypowers/skills ~/.agents/skills/rubypowers
# Restart Codex
```

If you used the **plugin path**:

```bash
codex plugin remove rubypowers@rubypowers
codex plugin marketplace remove rubypowers
# Reinstall whichever production setup you were on (symlink or plugin)
```

---

## 4. OpenCode

OpenCode's plugin URL syntax (`<name>@git+<url>#<ref>`) supports refs natively,
so branch testing is configuration-only.

### Test from GitHub branch (cleanest — no clone step)

Edit your `opencode.json` (global at `~/.config/opencode/opencode.json` or
project-level) and change the existing `rubypowers` plugin entry to
pin the branch:

```json
{
  "plugin": [
    "rubypowers@git+https://github.com/lucianghinda/rubypowers.git#lg/rename-compatibility"
  ]
}
```

Restart OpenCode. The `#<branch>` suffix tells OpenCode's installer to
fetch that ref instead of the default branch.

### Test from local working tree

The same plugin URL syntax accepts `file://` git URLs:

```json
{
  "plugin": [
    "rubypowers@git+file:///Users/lucianghinda/Dropbox/workprojects/opensource/rubypowers#lg/rename-compatibility"
  ]
}
```

Or run the existing test harness, which fakes a plugin install from the
working tree:

```bash
cd "$LOCAL_PATH"
bash tests/opencode/setup.sh
bash tests/opencode/test-tools.sh
bash tests/opencode/test-priority.sh
```

The setup script copies the working tree into a temp `$HOME` and registers
OpenCode's plugin pointer at `$TEST_HOME/.config/opencode/plugins/rubypowers.js`.

### Verify

- Plugin loads in logs:
  ```bash
  opencode run --print-logs "hello" 2>&1 | grep -i rubypowers
  ```
- Skill resolves via the OpenCode skill tool: ask OpenCode to
  `use skill tool to load rubypowers/handoff`.
- The existing `tests/opencode/test-tools.sh` smoke test asserts that
  `rubypowers:brainstorming` and `rubypowers:using-rubypowers`
  load correctly — run it as the regression check.

### Restore afterwards

Edit `opencode.json` back to the production install (no `#<ref>` suffix):

```json
{
  "plugin": [
    "rubypowers@git+https://github.com/lucianghinda/rubypowers.git"
  ]
}
```

…and restart OpenCode.

---

## Cross-platform regression checklist

Use this after testing on each platform to confirm there are no regressions
from the v7.0.0 bare-name change:

- [ ] All 6 originally-broken skills (`compound`, `compound-refresh`,
      `consulting-an-oracle`, `handoff`, `handoff-list`, `handoff-resume`)
      load on **Copilot CLI** with no validator errors.
- [ ] On **Claude Code**, the skills list shows each skill exactly once
      with no double-prefix display.
- [ ] On **Codex**, all 34 skills are discoverable (either via the symlink
      or via the plugin cache).
- [ ] On **OpenCode**, `tests/opencode/test-tools.sh` and
      `tests/opencode/test-priority.sh` pass.
- [ ] Slash-command invocation paths from the user's perspective are
      unchanged (`/rubypowers:handoff` still works).
- [ ] Skill cross-references in skill bodies use `rubypowers:<slug>`
      consistently (not legacy `superpowers:<slug>`).
- [ ] Manifest version (`7.0.0`) is consistent across all 6 versioned
      manifests: `.claude-plugin/plugin.json`,
      `.claude-plugin/marketplace.json`, `.cursor-plugin/plugin.json`,
      `.codex-plugin/plugin.json`, `package.json`, `gemini-extension.json`.

## Hotfix-revert paths

If a regression is found post-merge:

| What broke | Revert this commit |
|---|---|
| Copilot CLI loads but display is wrong | `git revert <bare-name-fix-commit>` |
| Cross-references in some skill body broken | `git revert <cross-ref-normalize-commit>` |
| Codex plugin install errors | `git revert <codex-plugin-commit>` (legacy symlink path remains) |
| Version-bump-only issue | `git revert <version-bump-commit>` |

The per-unit commit structure is designed so that any single unit can be
reverted independently without losing the others.
