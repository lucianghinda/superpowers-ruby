# Rename superpowers-ruby to RubyPowers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers-ruby:subagent-driven-development (recommended) or superpowers-ruby:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the plugin from `superpowers-ruby` (display name "Superpowers (Ruby)") to `rubypowers` (display name "RubyPowers") across every manifest, skill, hook, test, and doc, then rename the GitHub repo and local folder, and ship it as version 8.0.0.

**Architecture:** One Ruby script does the mechanical text replacement over `git ls-files`, skipping history files (CHANGELOG, RELEASE-NOTES, `docs/plans`, `docs/sessions`, `docs/handoffs`, and the old `docs/superpowers/` plan folder), which stay as written because they describe what the plugin was called at the time. Hand edits then cover the things a text replace cannot do safely: `git mv` of paths, the hooks' fallback for the old `docs/superpowers/` convention, the "migrating from the old name" sections that must keep the old name, the release entries, and the GitHub rename. A second Ruby script audits the tree and must show only the intentional leftovers.

**Tech Stack:** Bash hooks, JSON manifests (jq), Node for the OpenCode plugin, Ruby stdlib for the two scripts, `gh` CLI for the repo rename.

**Decisions (from the user, 2026-10-06):**
- Rename everything, including the upstream-shared conventions: `using-superpowers` -> `using-rubypowers`, `docs/superpowers/` -> `docs/rubypowers/` (hooks and skills keep reading the old path), `.opencode/plugins/superpowers.js` -> `rubypowers.js`.
- Leave history untouched. Only add new 8.0.0 entries.
- Display name is `RubyPowers`.
- Rename the GitHub repo to `lucianghinda/rubypowers`, the local folder, and the `origin` remote. GitHub redirects the old URL.
- Breaking change, so the version is 8.0.0.

**Out of scope:** Legacy `superpowers:` prefixes (no `-ruby`) that already exist in a few skills and test plans. They predate this fork's prefix and are a separate cleanup.

## Review amendments (2026-10-09)

These amendments override conflicting steps below and are part of the implementation acceptance criteria.

- **Complete current branding:** Audit all case-insensitive `superpowers` occurrences, including filenames, visible brainstorming HTML, OpenCode documentation titles, and `.superpowers/brainstorm` runtime storage. Rename current project branding to RubyPowers and current runtime storage to `.rubypowers/brainstorm`. Keep upstream URLs/attribution, historical documents, explicit migration instructions, and legacy compatibility reads intentional. Do not use a narrow replacement-pattern audit as proof of completeness.
- **Working Codex migration:** Updating `~/.codex/superpowers-ruby` does not create `~/.codex/rubypowers`. The old-bootstrap migration must explicitly create the new discovery symlink pointing at the existing old clone, or move the clone before linking. Keep subsequent update/uninstall instructions consistent with the selected installation path.
- **Consistent OpenCode fixtures:** Rename paths with and without a trailing slash, including the setup `mkdir`, and include `tests/opencode/test-priority.sh`. Execute the local setup/plugin-loading checks, not only `bash -n`. Remove obsolete setup dependencies if they reference directories no longer present in this repository.
- **Complete migration instructions:** The OpenCode symlink migration must explicitly direct users to install the new package after removing the old symlinks.
- **Consistent document locations:** Every save, promotion, review, and completion instruction must use the selected existing legacy directory or the new default; later instructions must not contradict the compatibility bullets.
- **Verification:** Add executable regression coverage for mixed old/new handoff paths and the Codex migration symlink. Verify runtime/bootstrap identity, manifests, OpenCode registration, visible branding, and retained history. Record unavailable platform checks honestly.
- **Execution:** Continue on the current PR branch. Use Ruby stdlib for utility scripts. Keep reviewable repository changes separate from the GitHub repository rename, local checkout move, merge, and release; those remain the post-approval steps in Task 13. Commit messages must follow the workspace Lore protocol rather than the example messages below.

### Execution status

- [x] Incorporate review findings into the plan.
- [x] Rename current identities, paths, and branding.
- [x] Implement compatibility and migration instructions.
- [x] Repair and run relevant tests; audit the complete diff.
- [x] Complete spec and quality reviews (Luna subagents; reported gaps fixed and re-reviewed).
- [ ] Post-approval repository rename, merge, and release (Task 13).

### Verification record (2026-10-09)

- `ruby tests/scripts/test-rename.rb`: eight checks pass, covering legacy/current/mixed/empty handoff documents, bootstrap output for Claude Code/Cursor/Copilot, and executing the documented Codex discovery-symlink migration against an existing clone fixture.
- `bash tests/opencode/run-tests.sh`: local plugin-loading suite passes. Setup now copies skills, hooks, and package metadata instead of the removed `lib/` directory.
- `node tests/brainstorm-server/ws-protocol.test.js`: 31 checks pass.
- `node tests/brainstorm-server/server.test.js`: 25 checks pass. Corrected its stale waiting-page expectation to the existing agent-neutral text.
- `bash tests/brainstorm-server/windows-lifecycle.test.sh`: eight checks pass; three Windows-only checks skipped on macOS. Corrected the stale `server.js` fixture path to `server.cjs`.
- `bash tests/scripts/test-fetch-changelogs.sh`: eight checks pass; network checks skipped because the network was unavailable.
- Claude CLI validates both plugin and marketplace manifests. All seven JSON manifests parse, all 31 Bash scripts parse, and all 35 skill frontmatter names match their folders.
- `scripts/bump-version.sh --check`: all six declared version fields are 8.0.0. Historical release entries and all six relocated plans/specs are byte-identical to the pre-rename versions.
- Broad, case-insensitive old-name audit reviewed: retained references are upstream attribution, migration/compatibility instructions and fixtures, the generic tagline, and the explicitly excluded legacy invocation/synthetic test fixtures.
- Full installed-platform/LLM integration checks were not run. Local validation does not establish live marketplace installation or remote URL availability. Repository rename, redirect checks, merge, tag, release, and reinstall remain post-approval work.

---

## Name map

| Old | New | Where it matters |
|-----|-----|------------------|
| `superpowers-ruby` (plugin id, skill prefix, repo slug, paths) | `rubypowers` | 6 manifests, 25 skills, hooks, tests, docs |
| `Superpowers (Ruby)` / `Superpowers Ruby` (display) | `RubyPowers` | `.codex-plugin`, `.cursor-plugin`, `.agents` marketplace, `.claude-plugin/marketplace.json`, `using-superpowers` skill |
| `using-superpowers` (bootstrap skill) | `using-rubypowers` | skill folder, `hooks/session-start`, `GEMINI.md`, OpenCode plugin, tests |
| `docs/superpowers/{plans,specs}` (convention) | `docs/rubypowers/{plans,specs}` + fallback read of old path | `hooks/handoff-create`, writing-plans, brainstorming, handoff, tests |
| `.opencode/plugins/superpowers.js` | `.opencode/plugins/rubypowers.js` | `package.json`, OpenCode tests and docs |
| `plugins/superpowers-ruby` (symlink) | `plugins/rubypowers` | `.agents/plugins/marketplace.json` |
| `superpowers-ruby.svg` | `rubypowers.svg` | not referenced in text |
| `lucianghinda/superpowers-ruby` (GitHub) | `lucianghinda/rubypowers` | all install commands and URLs |

Kept on purpose: the attribution text "based on Jesse Vincent's superpowers", the fork mention of `obra/superpowers`, the `upstream` remote, the `~/.config/superpowers/skills` legacy warning in `hooks/session-start`, and every pre-8.0 install path inside "migrating from" sections.

---

### Task 1: Branch and rename scripts

**Files:**
- Create: `$TMPDIR/rubypowers-rename.rb` (throwaway, not committed)
- Create: `$TMPDIR/rubypowers-audit.rb` (throwaway, not committed)

- [ ] **Step 1: Create the branch**

```bash
cd /Users/luciang/Dropbox/workprojects/opensource/superpowers-ruby
git checkout main && git pull
git checkout -b lg/rename-to-rubypowers
```

- [ ] **Step 2: Write the audit script**

This script lists every tracked, non-history line that still mentions an old name. It is the test for the whole plan: run it before (many hits) and after (only the intentional leftovers listed in Task 11).

```ruby
#!/usr/bin/env ruby
# Audit: list tracked, non-history lines that still use the old names.
# Usage: ruby rubypowers-audit.rb   (run from the repo root)

HISTORY = %r{\A(CHANGELOG\.md|RELEASE-NOTES\.md|docs/(plans|sessions|handoffs|superpowers|rubypowers)/)}
OLD_NAMES = /superpowers-ruby|using-superpowers|docs\/superpowers|Superpowers \(Ruby\)|Superpowers Ruby|\.opencode\/plugins\/superpowers\.js/

hits = 0
`git ls-files`.split("\n").each do |file|
  next if file =~ HISTORY
  next unless File.file?(file)
  next if File.binread(file).include?("\0")

  File.foreach(file).with_index(1) do |line, number|
    next unless line =~ OLD_NAMES
    hits += 1
    puts "#{file}:#{number}: #{line.strip[0, 160]}"
  end
end

puts "\n#{hits} line(s) still use an old name"
```

Save as `$TMPDIR/rubypowers-audit.rb`.

- [ ] **Step 3: Run the audit to record the baseline**

Run: `ruby $TMPDIR/rubypowers-audit.rb | tail -1`
Expected: about `330 line(s) still use an old name` (the exact count may differ by a few).

- [ ] **Step 4: Write the rename script**

Order matters: specific phrases come before the generic ones they contain.

```ruby
#!/usr/bin/env ruby
# One-off rename: superpowers-ruby -> rubypowers in tracked, non-history files.
# Usage: ruby rubypowers-rename.rb   (run from the repo root)

HISTORY = %r{\A(CHANGELOG\.md|RELEASE-NOTES\.md|docs/(plans|sessions|handoffs|superpowers|rubypowers)/)}

REPLACEMENTS = [
  ["Marketplace for Superpowers Ruby/Rails skills library", "Marketplace for RubyPowers, a Ruby/Rails skills library"],
  ["Superpowers (Ruby)", "RubyPowers"],
  ["Superpowers Ruby", "RubyPowers"],
  ["superpowers-ruby", "rubypowers"],
  ["using-superpowers", "using-rubypowers"],
  ["docs/superpowers/", "docs/rubypowers/"],
  [".opencode/plugins/superpowers.js", ".opencode/plugins/rubypowers.js"],
]

changed = []
`git ls-files`.split("\n").each do |file|
  next if file =~ HISTORY
  next unless File.file?(file)
  source = File.binread(file)
  next if source.include?("\0")

  result = REPLACEMENTS.reduce(source) { |text, (from, to)| text.gsub(from, to) }
  next if result == source

  File.binwrite(file, result)
  changed << file
end

puts changed
puts "#{changed.size} file(s) changed"
```

Save as `$TMPDIR/rubypowers-rename.rb`.

- [ ] **Step 5: Confirm the scripts parse**

Run: `ruby -c $TMPDIR/rubypowers-rename.rb && ruby -c $TMPDIR/rubypowers-audit.rb`
Expected: `Syntax OK` twice.

No commit in this task. The scripts stay outside the repo.

---

### Task 2: Move paths with git mv

**Files:**
- Move: `skills/using-superpowers/` -> `skills/using-rubypowers/`
- Move: `docs/superpowers/` -> `docs/rubypowers/`
- Move: `.opencode/plugins/superpowers.js` -> `.opencode/plugins/rubypowers.js`
- Move: `plugins/superpowers-ruby` (symlink) -> `plugins/rubypowers`
- Move: `superpowers-ruby.svg` -> `rubypowers.svg`

- [ ] **Step 1: Move the five paths**

```bash
git mv skills/using-superpowers skills/using-rubypowers
git mv docs/superpowers docs/rubypowers
git mv .opencode/plugins/superpowers.js .opencode/plugins/rubypowers.js
git mv plugins/superpowers-ruby plugins/rubypowers
git mv superpowers-ruby.svg rubypowers.svg
```

- [ ] **Step 2: Verify the symlink still points to the repo root**

Run: `ls -la plugins/ && readlink plugins/rubypowers`
Expected: `plugins/rubypowers -> ..` and `..` printed.

- [ ] **Step 3: Verify nothing else is named after the old name**

Run: `git ls-files | grep -i superpowers`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: move paths from superpowers-ruby to rubypowers names

Pure renames, no content changes. Content follows in the next commit so
git keeps rename detection clean.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Run the mechanical replacement

**Files:**
- Modify: about 55 tracked files (manifests, skills, hooks, tests, docs)

- [ ] **Step 1: Run the rename script**

Run: `ruby $TMPDIR/rubypowers-rename.rb`
Expected: a file list ending with roughly `55 file(s) changed`. The list must NOT contain `CHANGELOG.md`, `RELEASE-NOTES.md`, or anything under `docs/plans/`, `docs/sessions/`, `docs/handoffs/`, `docs/rubypowers/`.

- [ ] **Step 2: Check that the manifests are still valid JSON**

```bash
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json \
         .codex-plugin/plugin.json .cursor-plugin/plugin.json \
         .agents/plugins/marketplace.json gemini-extension.json package.json; do
  jq -e . "$f" > /dev/null && echo "ok  $f"
done
```
Expected: seven `ok` lines.

- [ ] **Step 3: Check the identity fields**

```bash
jq -r '.name' .claude-plugin/plugin.json .codex-plugin/plugin.json .cursor-plugin/plugin.json gemini-extension.json .agents/plugins/marketplace.json .claude-plugin/marketplace.json
jq -r '.plugins[0].name, .plugins[0].source.path' .agents/plugins/marketplace.json
jq -r '.interface.displayName' .codex-plugin/plugin.json .agents/plugins/marketplace.json
jq -r '.displayName' .cursor-plugin/plugin.json
jq -r '.description' .claude-plugin/marketplace.json
```
Expected:
```
rubypowers   (x6)
rubypowers
./plugins/rubypowers
RubyPowers   (x3)
Marketplace for RubyPowers, a Ruby/Rails skills library
```

- [ ] **Step 4: Run the audit**

Run: `ruby $TMPDIR/rubypowers-audit.rb | tail -1`
Expected: `0 line(s) still use an old name`. The script covers every pattern the audit checks. If the count is not zero, the script missed a file. Fix the script and re-run it, do not hand-edit.

Bare-word leftovers such as `You have superpowers for Ruby and Rails` and the plain titles `# Installing Superpowers for Codex` and `# Superpowers for Codex` are not matched by the audit. They are fixed by hand in Tasks 4, 5, and 7.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "refactor: rename superpowers-ruby to rubypowers in manifests, skills, hooks, tests, docs

Mechanical replacement over tracked non-history files:
- plugin id and skill prefix: superpowers-ruby -> rubypowers
- display name: Superpowers (Ruby) -> RubyPowers
- bootstrap skill: using-superpowers -> using-rubypowers
- plans/specs convention: docs/superpowers/ -> docs/rubypowers/
- OpenCode entry point: superpowers.js -> rubypowers.js

CHANGELOG, RELEASE-NOTES, docs/plans, docs/sessions, docs/handoffs and
the old docs/superpowers plans are left as written.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: Hooks: bootstrap wording and old-path fallback

**Files:**
- Modify: `hooks/session-start:2,35`
- Modify: `hooks/handoff-create:2,58-74`
- Modify: `hooks/handoff-restore:2`

- [ ] **Step 1: Update the session-start header and bootstrap sentence**

In `hooks/session-start`, line 2:
```bash
# SessionStart hook for rubypowers plugin
```
Line 35, change the start of `session_context` from `You have superpowers for Ruby and Rails.` to:
```bash
session_context="<EXTREMELY_IMPORTANT>\nYou have RubyPowers: superpowers for Ruby and Rails.\n\n**Below is the full content of your 'rubypowers:using-rubypowers' skill - your introduction to using skills. For all other skills, use the 'Skill' tool:**\n\n${using_superpowers_escaped}\n\n${warning_escaped}\n</EXTREMELY_IMPORTANT>"
```
Leave the `legacy_skills_dir` warning block alone. It is about upstream's old `~/.config/superpowers/skills` location.

- [ ] **Step 2: Add the old-path fallback in handoff-create**

In `hooks/handoff-create`, line 2 becomes `# PreCompact / manual handoff hook for rubypowers plugin`.

Replace the two blocks that read `docs/rubypowers/specs` and `docs/rubypowers/plans` (lines 58 to 74 after Task 3) with loops that read the new path first and the pre-8.0 path second:

```bash
# RubyPowers specs (docs/rubypowers/, falling back to the pre-8.0 docs/superpowers/ path)
for specs_dir in "${PROJECT_ROOT}/docs/rubypowers/specs" "${PROJECT_ROOT}/docs/superpowers/specs"; do
  [ -d "$specs_dir" ] || continue
  for f in "$specs_dir"/*.md; do
    [ -f "$f" ] || continue
    rel="${f#"${PROJECT_ROOT}/"}"
    FILES_TO_READ="${FILES_TO_READ}- \`${rel}\` (spec)\n"
  done
done

# RubyPowers plans (same fallback)
for plans_dir in "${PROJECT_ROOT}/docs/rubypowers/plans" "${PROJECT_ROOT}/docs/superpowers/plans"; do
  [ -d "$plans_dir" ] || continue
  for f in "$plans_dir"/*.md; do
    [ -f "$f" ] || continue
    rel="${f#"${PROJECT_ROOT}/"}"
    FILES_TO_READ="${FILES_TO_READ}- \`${rel}\` (plan)\n"
  done
done
```

- [ ] **Step 3: Update the handoff-restore header**

`hooks/handoff-restore`, line 2: `# PostCompact hook for rubypowers plugin`.

- [ ] **Step 4: Syntax-check and run the session-start hook**

```bash
bash -n hooks/session-start hooks/handoff-create hooks/handoff-restore
CLAUDE_PLUGIN_ROOT="$PWD" hooks/session-start | jq -r '.hookSpecificOutput.additionalContext' | head -5
```
Expected: no syntax errors, then output starting with:
```
<EXTREMELY_IMPORTANT>
You have RubyPowers: superpowers for Ruby and Rails.

**Below is the full content of your 'rubypowers:using-rubypowers' skill ...
```
If `jq` fails, the JSON escaping broke. Re-check the quotes in Step 1.

- [ ] **Step 5: Test the handoff fallback against both folder names**

```bash
TMP_PROJ=$(mktemp -d) && cd "$TMP_PROJ" && git init -q && git commit -q --allow-empty -m init
mkdir -p docs/superpowers/plans docs/rubypowers/specs
echo "# old plan" > docs/superpowers/plans/old.md
echo "# new spec" > docs/rubypowers/specs/new.md
bash /Users/luciang/Dropbox/workprojects/opensource/superpowers-ruby/hooks/handoff-create --trigger manual > /dev/null
grep -h "old.md\|new.md" docs/handoffs/*.md
cd - > /dev/null && rm -rf "$TMP_PROJ"
```
Expected: two lines, one listing `docs/superpowers/plans/old.md` as `(plan)` and one listing `docs/rubypowers/specs/new.md` as `(spec)`.

- [ ] **Step 6: Commit**

```bash
git add hooks/
git commit -m "feat(hooks): announce RubyPowers and read both docs/rubypowers and docs/superpowers

Projects started before 8.0.0 keep their plans and specs under
docs/superpowers/. The handoff hook reads both locations so nothing
is lost after the rename.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: OpenCode plugin and package.json

**Files:**
- Modify: `.opencode/plugins/rubypowers.js:1-6,37,42,58`
- Modify: `package.json`

- [ ] **Step 1: Update the plugin header, export name, and bootstrap sentence**

In `.opencode/plugins/rubypowers.js`:

Lines 1 to 6:
```js
/**
 * RubyPowers plugin for OpenCode.ai
 *
 * Injects rubypowers bootstrap context into the first user message.
 * Auto-registers skills directory via config hook (no symlinks needed).
 */
```

Line 37 (export and directory variable):
```js
export const RubyPowersPlugin = async ({ client, directory }) => {
  const rubypowersSkillsDir = path.resolve(__dirname, '../../skills');
```
Then replace every other `superpowersSkillsDir` in the file with `rubypowersSkillsDir` (lines 42, 76, 77 before this edit). Run `grep -n superpowersSkillsDir .opencode/plugins/rubypowers.js` and expect no output.

Line 58, inside the template string:
```js
You have RubyPowers: superpowers for Ruby and Rails.
```

- [ ] **Step 2: Rewrite package.json**

```json
{
  "name": "rubypowers",
  "version": "7.5.0",
  "type": "module",
  "main": ".opencode/plugins/rubypowers.js"
}
```
(The version is bumped in Task 9.)

- [ ] **Step 3: Verify**

```bash
node -c .opencode/plugins/rubypowers.js && echo "syntax ok"
node -e "import('./.opencode/plugins/rubypowers.js').then(m => console.log(Object.keys(m)))"
jq -r '.name, .main' package.json
```
Expected:
```
syntax ok
[ 'RubyPowersPlugin' ]
rubypowers
.opencode/plugins/rubypowers.js
```

- [ ] **Step 4: Commit**

```bash
git add .opencode/plugins/rubypowers.js package.json
git commit -m "refactor(opencode): rename plugin entry point and export to RubyPowers

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: Skills: old-path compatibility notes

The replacement already points the skills at `docs/rubypowers/`. These edits keep agents working in projects that still have `docs/superpowers/`.

**Files:**
- Modify: `skills/writing-plans/SKILL.md:18`
- Modify: `skills/brainstorming/SKILL.md:35`
- Modify: `skills/handoff/SKILL.md:51-52`

- [ ] **Step 1: writing-plans save location**

Replace line 18 (`**Save plans to:** \`docs/rubypowers/plans/YYYY-MM-DD-<feature-name>.md\``) with:

```markdown
**Save plans to:** `docs/rubypowers/plans/YYYY-MM-DD-<feature-name>.md`
- If the project already has `docs/superpowers/plans/` (created before RubyPowers 8.0.0), keep using that folder. Do not maintain two plan folders in one project.
- (User preferences for plan location override this default)
```
Remove the old `- (User preferences ...)` line that followed line 18 so it is not duplicated.

- [ ] **Step 2: brainstorming spec location**

After line 35 (the step that promotes the draft to `docs/rubypowers/specs/...`), add one line in the same list indentation:

```markdown
   - If the project already has `docs/superpowers/specs/` from before RubyPowers 8.0.0, write there instead so all specs stay in one folder
```

- [ ] **Step 3: handoff plan detection**

Replace lines 51 and 52 with four lines:

```bash
ls docs/rubypowers/specs/*.md 2>/dev/null
ls docs/rubypowers/plans/*.md 2>/dev/null
ls docs/superpowers/specs/*.md 2>/dev/null   # pre-8.0 location
ls docs/superpowers/plans/*.md 2>/dev/null   # pre-8.0 location
```

- [ ] **Step 4: Verify the frontmatter of the renamed bootstrap skill**

Run: `sed -n '1,4p' skills/using-rubypowers/SKILL.md`
Expected:
```
---
name: using-rubypowers
description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
---
```
Run: `cat GEMINI.md`
Expected both lines point at `./skills/using-rubypowers/...`.

- [ ] **Step 5: Commit**

```bash
git add skills/
git commit -m "docs(skills): keep reading docs/superpowers in projects created before 8.0.0

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: Install docs: restore old names in "migrating from" sections and add 8.0 migration

The script renamed every path, including the paths of installs that predate 8.0.0. Those must say the old name because that is what sits on the user's disk.

**Files:**
- Modify: `.opencode/INSTALL.md:1,21-33`
- Modify: `docs/README.opencode.md:19-31`
- Modify: `.codex/INSTALL.md:1,68-80,99-110`
- Modify: `README.md:1,3,55,152-160`

- [ ] **Step 1: .opencode/INSTALL.md**

Line 1: `# Installing RubyPowers for OpenCode`.

Replace the "Migrating from the old symlink-based install" section (lines 21 to 33) with:

````markdown
## Migrating from superpowers-ruby (before 8.0.0)

RubyPowers was called `superpowers-ruby` until 8.0.0. Replace the old plugin line in `opencode.json`:

```json
{
  "plugin": ["rubypowers@git+https://github.com/lucianghinda/rubypowers.git"]
}
```

Restart OpenCode. Plans and specs already in `docs/superpowers/` keep working; new ones go to `docs/rubypowers/`.

## Migrating from the old symlink-based install

If you previously installed superpowers-ruby using `git clone` and symlinks, remove the old setup:

```bash
# Remove old symlinks
rm -f ~/.config/opencode/plugins/superpowers.js
rm -rf ~/.config/opencode/skills/superpowers-ruby

# Optionally remove the cloned repo
rm -rf ~/.config/opencode/superpowers-ruby

# Remove skills.paths from opencode.json if you added one for superpowers-ruby
```
````

- [ ] **Step 2: docs/README.opencode.md**

Replace lines 19 to 31 (the same symlink section) with the same two sections as Step 1. Also change the `#v6.0.0` pin on line 87 to `#v8.0.0`.

- [ ] **Step 3: .codex/INSTALL.md**

Line 1: `# Installing RubyPowers for Codex` (currently `# Installing Superpowers for Codex`). Also change `docs/README.codex.md` line 1 from `# Superpowers for Codex` to `# RubyPowers for Codex`, and line 3 from `Guide for using Superpowers with OpenAI Codex` to `Guide for using RubyPowers with OpenAI Codex`.

Insert after the "Quick install" block (after line 20, the `codex plugin add rubypowers@rubypowers` line and its closing fence):

````markdown
## Migrating from superpowers-ruby (before 8.0.0)

```bash
codex plugin remove superpowers-ruby@superpowers-ruby
codex plugin marketplace add lucianghinda/rubypowers
codex plugin add rubypowers@rubypowers
```
````

In "Migrating from old bootstrap" (lines 68 to 80), the update command must keep the old clone path:
```bash
cd ~/.codex/superpowers-ruby && git pull
```
In "Migrating from symlink to plugin" (lines 99 to 110), the removal must keep the old symlink name:
```bash
rm ~/.agents/skills/superpowers-ruby
```
The two `codex plugin ...` lines after it stay with the new name.

- [ ] **Step 4: README.md**

Line 1: `# RubyPowers`

Line 3:
```markdown
A Ruby on Rails–focused fork of [obra/superpowers](https://github.com/obra/superpowers) — a complete software development workflow for coding agents built on composable "skills". Known as `superpowers-ruby` before version 8.0.0.
```

Insert a new section right before `## Updating` (around line 244):

````markdown
## Migrating from superpowers-ruby

Version 8.0.0 renamed the plugin to `rubypowers`. The old install is not updated in place. Remove it and install the new name:

| Platform | Commands |
|----------|----------|
| **Claude Code** | `/plugin uninstall superpowers-ruby@superpowers-ruby`, `/plugin marketplace remove superpowers-ruby`, then `/plugin marketplace add lucianghinda/rubypowers` and `/plugin install rubypowers@rubypowers` |
| **Codex** | `codex plugin remove superpowers-ruby@superpowers-ruby`, then `codex plugin marketplace add lucianghinda/rubypowers` and `codex plugin add rubypowers@rubypowers` |
| **GitHub Copilot CLI** | `copilot plugin uninstall superpowers-ruby`, then `copilot plugin marketplace add lucianghinda/rubypowers` and `copilot plugin install rubypowers@rubypowers` |
| **Cursor** | `cd ~/.cursor/plugins/local && git clone https://github.com/lucianghinda/rubypowers && rm -rf superpowers-ruby` |
| **OpenCode** | Replace the plugin line in `opencode.json` with `rubypowers@git+https://github.com/lucianghinda/rubypowers.git` |
| **Gemini CLI** | `gemini extensions uninstall superpowers-ruby` then `gemini extensions install https://github.com/lucianghinda/rubypowers` |

Skill names change prefix: `superpowers-ruby:brainstorming` becomes `rubypowers:brainstorming`. Plans and specs already in `docs/superpowers/` keep working. New ones are written to `docs/rubypowers/`. The old GitHub URL redirects to the new one.
````

- [ ] **Step 5: Verify the install table reads correctly**

Run: `sed -n '64,72p' README.md`
Expected: every row uses `lucianghinda/rubypowers` and `rubypowers@rubypowers`.

- [ ] **Step 6: Commit**

```bash
git add README.md .opencode/INSTALL.md .codex/INSTALL.md docs/README.opencode.md docs/README.codex.md
git commit -m "docs: add superpowers-ruby to rubypowers migration and keep old names in legacy sections

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: OpenCode test harness paths

The replacement did not touch `~/.config/opencode/superpowers/` because that string has no `-ruby`. The tests install into that folder and register `superpowers.js`. Rename both so the harness matches the new file.

**Files:**
- Modify: `tests/opencode/setup.sh:21-27,60-61`
- Modify: `tests/opencode/test-plugin-loading.sh:18-26,45,54`
- Modify: `docs/testing-plugin-installs.md:44,254`

- [ ] **Step 1: Replace in the three files**

```ruby
# $TMPDIR/opencode-paths.rb  (throwaway)
files = %w[tests/opencode/setup.sh tests/opencode/test-plugin-loading.sh docs/testing-plugin-installs.md]
files.each do |f|
  text = File.read(f)
  text = text.gsub("opencode/superpowers/", "opencode/rubypowers/")
  text = text.gsub("opencode/plugins/superpowers.js", "opencode/plugins/rubypowers.js")
  File.write(f, text)
end
```
Run: `ruby $TMPDIR/opencode-paths.rb && grep -n "superpowers" tests/opencode/setup.sh tests/opencode/test-plugin-loading.sh`
Expected: no output from grep.

- [ ] **Step 2: Check the docs file keeps its legacy mention only where intended**

Run: `grep -n "superpowers" docs/testing-plugin-installs.md`
Expected: no output. This doc describes testing the current branch, so it has no legacy section.

- [ ] **Step 3: Dry-run the OpenCode setup script**

Run: `bash -n tests/opencode/setup.sh tests/opencode/test-plugin-loading.sh tests/opencode/test-tools.sh && echo ok`
Expected: `ok`.

- [ ] **Step 4: Commit**

```bash
git add tests/opencode docs/testing-plugin-installs.md
git commit -m "test(opencode): install and register rubypowers.js in the test harness

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 9: Version 8.0.0 and release notes

Nine locations per bump: six JSON manifests through the script, then CHANGELOG, RELEASE-NOTES, and the `#vX.Y.Z` pins by hand.

**Files:**
- Modify: six manifests via `scripts/bump-version.sh`
- Modify: `.opencode/INSTALL.md` (pin), `docs/README.opencode.md` (pin, done in Task 7)
- Modify: `CHANGELOG.md:3-5`
- Modify: `RELEASE-NOTES.md:1-3`

- [ ] **Step 1: Bump the manifests**

Run: `scripts/bump-version.sh 8.0.0`
Expected: six lines `7.5.0 -> 8.0.0`, then the audit. The audit lists `.opencode/INSTALL.md` as an undeclared file containing `7.5.0`. Fix the pin:

```bash
grep -rn "#v7.5.0" --include=*.md . | grep -v CHANGELOG | grep -v RELEASE-NOTES
```
Change each `#v7.5.0` to `#v8.0.0`. Re-run `scripts/bump-version.sh --audit` and expect `No undeclared files contain the version string. All clear.`

- [ ] **Step 2: CHANGELOG entry**

Under `## [Unreleased]` insert, dated today:

```markdown
## [8.0.0] - 2026-10-06

### Changed

- **BREAKING: plugin renamed from `superpowers-ruby` to `rubypowers`** (display name **RubyPowers**). The plugin id, marketplace name, skill prefix (`rubypowers:brainstorming`), repository (`lucianghinda/rubypowers`), bootstrap skill (`using-rubypowers`), OpenCode entry point (`.opencode/plugins/rubypowers.js`), and the plans/specs convention (`docs/rubypowers/`) all carry the new name. Existing installs are not updated in place: uninstall `superpowers-ruby` and install `rubypowers` (see the README "Migrating from superpowers-ruby" section). The `handoff` hook and the `writing-plans`, `brainstorming`, and `handoff` skills keep reading `docs/superpowers/` so projects started before 8.0.0 lose nothing. The old GitHub URL redirects. Changelog and release-note entries before 8.0.0 keep the old name on purpose.
```

- [ ] **Step 3: RELEASE-NOTES entry**

Line 1 becomes `# RubyPowers Release Notes`. Insert after it:

```markdown
## v8.0.0 (2026-10-06)

### superpowers-ruby Is Now RubyPowers

This fork started in October 2025 as a Ruby-flavoured copy of obra/superpowers. Since then it has grown into a Ruby and Rails skills library in its own right: 35 skills covering Minitest-first TDD, the Rails guides, Hotwire, Brakeman, Sandi Metz rules, 37signals style, and Ruby and Rails upgrades. The name "Superpowers (Ruby)" described a variant of another plugin. "RubyPowers" describes what the plugin is today, superpowers for Ruby developers, and gives it a name that cannot be confused with the upstream plugin when both are installed. The workflow core still comes from Jesse Vincent's obra/superpowers, and the README and manifests keep that credit.

- **What changed** — plugin id `rubypowers`, display name **RubyPowers**, skill prefix `rubypowers:`, repo `lucianghinda/rubypowers`, bootstrap skill `using-rubypowers`, OpenCode entry `rubypowers.js`, new plans and specs under `docs/rubypowers/`.
- **What you must do** — uninstall `superpowers-ruby` and install `rubypowers` on your platform. Package managers treat the new name as a different plugin, so there is no in-place update. Commands for each platform are in the README under "Migrating from superpowers-ruby".
- **What keeps working** — plans and specs already in `docs/superpowers/` are still found by the handoff hook and the planning skills. Old GitHub links redirect. History entries below this one keep the old name because that is what the plugin was called when they shipped.
```

- [ ] **Step 4: Verify**

```bash
scripts/bump-version.sh --check
grep -c "8.0.0" CHANGELOG.md RELEASE-NOTES.md
```
Expected: `All declared files are in sync at 8.0.0`, and a count of at least 1 for each file.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "chore(release): bump version to 8.0.0

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 10: Smoke-test the plugin under Claude Code

**Files:** none modified.

- [ ] **Step 1: Load the plugin from the working tree and ask about skills**

```bash
cd $(mktemp -d) && git init -q
claude -p --plugin-dir /Users/luciang/Dropbox/workprojects/opensource/superpowers-ruby \
  "List the first five skill names you have available and the plugin they come from. Answer in one line each." 2>&1 | head -20
```
Expected: lines showing names prefixed `rubypowers:` (for example `rubypowers:brainstorming`) and no `superpowers-ruby:` anywhere.

- [ ] **Step 2: Confirm the bootstrap skill name is what the session hook announces**

```bash
cd /Users/luciang/Dropbox/workprojects/opensource/superpowers-ruby
CLAUDE_PLUGIN_ROOT="$PWD" hooks/session-start | jq -r '.hookSpecificOutput.additionalContext' | grep -o "rubypowers:using-rubypowers"
```
Expected: `rubypowers:using-rubypowers`.

- [ ] **Step 3: Run the Codex and Copilot manifest checks from the testing doc**

Follow the "Codex" and "Copilot CLI" sections of `docs/testing-plugin-installs.md` for the local branch. Expected: both platforms list `rubypowers` as the installed plugin and load `rubypowers:brainstorming`. If either platform is not installed on this machine, record "skipped: <platform> not installed" in the PR description instead of claiming it passed.

---

### Task 11: Final audit

**Files:** none modified.

- [ ] **Step 1: Run the audit script**

Run: `ruby $TMPDIR/rubypowers-audit.rb`
Expected: the only remaining hits are the intentional leftovers below. Anything else is a miss.

```
hooks/handoff-create         docs/superpowers/specs and docs/superpowers/plans fallback (2 lines)
skills/handoff/SKILL.md      two ls lines marked "pre-8.0 location"
skills/writing-plans/SKILL.md     one compatibility bullet mentioning docs/superpowers/plans/
skills/brainstorming/SKILL.md     one compatibility bullet mentioning docs/superpowers/specs/
README.md                    title line 3 and the "Migrating from superpowers-ruby" table
.opencode/INSTALL.md         the two migration sections
docs/README.opencode.md      the two migration sections
.codex/INSTALL.md            the three migration sections
```

- [ ] **Step 2: Confirm history files were not touched**

Run: `git diff main --stat -- CHANGELOG.md RELEASE-NOTES.md docs/plans docs/sessions docs/handoffs docs/rubypowers`
Expected: only `CHANGELOG.md` and `RELEASE-NOTES.md` appear, each with the inserted lines only (plus the one-line title change in RELEASE-NOTES). `docs/rubypowers/*` shows as pure renames with 100% similarity.

- [ ] **Step 3: Delete the throwaway scripts**

```bash
rm -f $TMPDIR/rubypowers-rename.rb $TMPDIR/rubypowers-audit.rb $TMPDIR/opencode-paths.rb
```

---

### Task 12: Pull request

**Files:** none modified.

- [ ] **Step 1: Push and open the PR against the fork**

The PR goes to `lucianghinda/superpowers-ruby` (still the repo name at this point), never to `obra/superpowers`.

```bash
git push -u origin lg/rename-to-rubypowers
gh pr create --repo lucianghinda/superpowers-ruby --base main --title "Rename plugin to rubypowers (RubyPowers) for 8.0.0" --body "$(cat <<'EOF'
## What problem are you trying to solve?
The plugin is being renamed from `superpowers-ruby` to `rubypowers` (display name RubyPowers).

## What does this PR change?
Renames the plugin id, skill prefix, display name, bootstrap skill, OpenCode entry point, and plans/specs convention. Adds migration docs. Bumps to 8.0.0. History files are unchanged.

## Compatibility
- Existing installs must be removed and reinstalled under the new name (documented in README).
- `docs/superpowers/` in user projects is still read by the handoff hook and the planning skills.
- GitHub repo rename to `lucianghinda/rubypowers` happens right before merge (Task 13 of the plan), so the new URLs in this PR resolve.

## Environment tested
Claude Code with `--plugin-dir`; session-start hook output validated with jq; OpenCode plugin import checked with node.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 2: Review the diff yourself before asking for a merge**

Run: `gh pr diff --repo lucianghinda/superpowers-ruby | grep "^-.*superpowers-ruby" | wc -l`
Expected: a large number (every removed old-name line). Then: `gh pr diff --repo lucianghinda/superpowers-ruby | grep "^+.*superpowers-ruby"` and confirm every line is inside a migration section, the README title paragraph, or a `pre-8.0` comment.

---

### Task 13: Rename the GitHub repo, local folder, and remote

Do this after the PR is approved and immediately before merging, so the new URLs in the merged README resolve.

**Files:** none in the repo.

- [ ] **Step 1: Rename on GitHub**

```bash
gh repo rename rubypowers --repo lucianghinda/superpowers-ruby --yes
gh repo view lucianghinda/rubypowers --json name,url -q '.url'
```
Expected: `https://github.com/lucianghinda/rubypowers`. GitHub redirects `lucianghinda/superpowers-ruby` to it for both web and git.

- [ ] **Step 2: Merge the PR**

```bash
gh pr merge --repo lucianghinda/rubypowers lg/rename-to-rubypowers --merge
```

- [ ] **Step 3: Update the remote and local folder**

```bash
cd /Users/luciang/Dropbox/workprojects/opensource/superpowers-ruby
git remote set-url origin https://github.com/lucianghinda/rubypowers.git
git checkout main && git pull
cd .. && mv superpowers-ruby rubypowers && cd rubypowers
git remote -v
```
Expected: `origin` points at `rubypowers.git`, `upstream` still at `obra/superpowers.git`.

- [ ] **Step 4: Move Claude Code's per-project memory**

Claude Code keys project memory on the folder path. Copy it so earlier notes follow the project:

```bash
cp -R "$HOME/.claude/projects/-Users-luciang-Dropbox-workprojects-opensource-superpowers-ruby/memory" \
      "$HOME/.claude/projects/-Users-luciang-Dropbox-workprojects-opensource-rubypowers/memory"
```
If the destination folder does not exist yet, open Claude Code once in the new folder first, then run the copy.

- [ ] **Step 5: Tag and release**

```bash
git tag -a v8.0.0 -m "RubyPowers 8.0.0: renamed from superpowers-ruby"
git push origin v8.0.0
gh release create v8.0.0 --repo lucianghinda/rubypowers --title "v8.0.0 — RubyPowers" --notes-file <(sed -n '/^## v8.0.0/,/^## v7.5.0/p' RELEASE-NOTES.md | sed '$d')
```

- [ ] **Step 6: Reinstall the plugin on this machine**

In Claude Code:
```
/plugin uninstall superpowers-ruby@superpowers-ruby
/plugin marketplace remove superpowers-ruby
/plugin marketplace add lucianghinda/rubypowers
/plugin install rubypowers@rubypowers
```
Start a new session and confirm the session-start banner says `rubypowers:using-rubypowers`.

---

## Self-review

- **Coverage:** identity (Tasks 2, 3), conventions (Tasks 2, 4, 5, 6), history untouched (script exclusions, Task 11 check), display name (Task 3 script), repo rename (Task 13), version 8.0.0 (Task 9), migration docs (Task 7), tests (Task 8), verification (Tasks 10, 11).
- **Placeholder scan:** none. The rename rationale in Task 9 Step 3 is written.
- **Name consistency:** `rubypowers` (id), `RubyPowers` (display), `using-rubypowers` (skill), `rubypowers.js` (entry), `RubyPowersPlugin` (export), `docs/rubypowers/` (convention) are used identically across all tasks.
