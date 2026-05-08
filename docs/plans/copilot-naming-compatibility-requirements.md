# Copilot Naming Compatibility Requirements

**Version:** 1.0
**Status:** Draft
**Date:** 2026-05-08
**Branch:** `lg/rename-compatibility`
**Supersedes:** PR [#12](https://github.com/lucianghinda/superpowers-ruby/pull/12)

## Problem Frame

Copilot CLI's skill loader validates the `name:` field of every SKILL.md against a regex that allows only letters, numbers, hyphens, underscores, dots, and spaces. Six skills in this plugin (`compound`, `compound-refresh`, `handoff`, `handoff-list`, `handoff-resume`, `consulting-an-oracle`) declare their `name:` as `superpowers-ruby:<skill>` with a colon — Copilot rejects them with:

```
✖ name: Skill name must contain only letters, numbers, hyphens,
        underscores, dots, and spaces
```

The remaining 28 skills declare bare names (`name: brainstorming`) and load correctly on every platform because each platform's loader auto-prefixes them via the plugin manifest. PR [#12](https://github.com/lucianghinda/superpowers-ruby/pull/12) proposed a minimal fix — replacing `:` with `-` in only the 5 broken skills it knew about (consulting-an-oracle did not exist when #12 was opened).

This refactor takes a different position: instead of the surgical fix, we make the naming **uniform across all 34 skills** by setting every `name:` field to `superpowers-ruby.<skill-slug>` using a dot. The dot is preferred over a hyphen because it visually preserves the namespace–skill boundary (`superpowers-ruby.compound` parses obviously as plugin + skill, while `superpowers-ruby-compound` reads as a single hyphenated token).

The user has explicitly accepted that this change has not been tested across Claude Code, Cursor, and OpenCode and may surface platform-specific loader behavior — manual verification is part of the implementation plan.

## Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| R1 | Every SKILL.md frontmatter must declare `name: superpowers-ruby.<skill-slug>` | Must Have | All 34 skills under `skills/`. Slug must match the directory name. |
| R2 | All 34 skills must load successfully under Copilot CLI without validator errors | Must Have | This is the originating bug from PR #12. Verified by running `copilot` and listing skills. |
| R3 | All 34 skills must remain invokable from Claude Code via the Skill tool | Must Have | Verified by `/skills` listing showing each skill exactly once with a sane display name (no double-prefix like `superpowers-ruby:superpowers-ruby.<x>`). |
| R4 | The skill catalog in `skills/using-superpowers/SKILL.md` must reference each skill as `superpowers-ruby.<skill-slug>` | Must Have | Currently 28 entries use the colon form. The catalog teaches users how to invoke skills, so it must match the `name:` declared in the frontmatter. |
| R5 | Any other markdown body content that references skills as `superpowers-ruby:<x>` must be updated to `superpowers-ruby.<x>` | Must Have | Audit: 6 SKILL.md files reference their own name in body content; using-superpowers also references many. Scope of cross-reference audit: `skills/`, `agents/`, `commands/`. |
| R6 | PR [#12](https://github.com/lucianghinda/superpowers-ruby/pull/12) must be closed with a comment crediting the contributor and explaining why this branch supersedes it | Must Have | Maintains contributor good will; provides historical record of the design choice. |
| R7 | A CHANGELOG/RELEASE-NOTES entry describing the rename must be added, following the format of existing entries | Should Have | Existing entries: see `RELEASE-NOTES.md` and `CHANGELOG.md`. Note: this is a user-visible naming change. |
| R8 | The plugin version must be bumped per `.version-bump.json` conventions | Should Have | Current version: 6.5.0. This is a behavior-preserving naming change that fixes a Copilot bug — likely 6.6.0 (minor). All 4 manifests must move in lockstep (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.cursor-plugin/plugin.json`, `package.json`, `gemini-extension.json`). |
| R9 | The 34 skills should continue to load on Cursor and OpenCode | Should Have | User has not pre-tested. If a regression is found post-merge, a hotfix (revert to bare names for working skills) must be ready. |
| R10 | Top-level docs (`README.md`) that reference skill names should be audited and updated for consistency where the dot form makes sense | Nice to Have | If references are abstract ("the brainstorming skill"), no change needed. Only update if the doc shows the literal invocation form. |

## Success Criteria

The rename is successful when **all** of the following are observable:

1. `copilot /skills` (or equivalent listing) shows all 34 superpowers-ruby skills without any of the historical "Skill name must contain only..." errors.
2. In Claude Code, `/skills` (or the system reminder skills list) shows each renamed skill exactly once, with no double-prefixed display strings.
3. Invoking any of the 6 originally-broken skills (`compound`, `compound-refresh`, `handoff`, `handoff-list`, `handoff-resume`, `consulting-an-oracle`) by its new dot-form name in Copilot succeeds and the skill content loads.
4. `grep -r "superpowers-ruby:" skills/ commands/ agents/` returns either zero matches or only matches that are intentional (e.g., a historical note quoting the old form).
5. PR #12 is closed with a comment that names this branch's PR.
6. The version bump and CHANGELOG entry exist in the merge commit.

## Scope Boundaries

**In scope:**
- The `name:` field in all 34 `skills/<skill>/SKILL.md` files
- The catalog table in `skills/using-superpowers/SKILL.md`
- Body-text cross-references inside `skills/`, `commands/`, `agents/` that use the literal string `superpowers-ruby:`
- The plugin version bump across all manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.cursor-plugin/plugin.json`, `package.json`, `gemini-extension.json`)
- A `RELEASE-NOTES.md` and/or `CHANGELOG.md` entry
- A close comment on PR #12

**Out of scope:**
- Renaming any skill folder under `skills/` (folder names are unchanged)
- Renaming any agent under `agents/` (only `code-reviewer.md` exists; no compatibility issue)
- Renaming any command under `commands/`
- Modifying hooks or scripts
- Adding automated cross-platform tests for skill loading (a one-off verification is in scope; CI integration is not)
- Changing the slug of any skill (e.g., `handoff-list` → `handoff_list`); only the prefix is added
- Restructuring `RELEASE-NOTES.md` historical entries
- Touching `resource-for-ruby/` (third-party content)

## Key Decisions

| Decision | Chosen | Rationale | Alternatives Considered |
|----------|--------|-----------|------------------------|
| Separator character | `.` (dot) | Preserves visual `namespace.skill` parsing. Passes Copilot's regex. User preference. | `-` (PR #12's choice — visually fuses the prefix into the slug); keeping `:` and providing per-platform shims (rejected: too much loader complexity) |
| Rename scope | All 34 skills | Uniform naming across the entire catalog. User explicitly chose uniformity over surgical fix. | Only the 6 broken skills (PR #12's surgical scope — leaves catalog inconsistent across platforms); only the catalog (would leave the 6 broken skills broken) |
| PR #12 disposition | Supersede + close with comment | Single coherent history. Acknowledges contributor. | Cherry-pick PR #12 first then expand (creates two commits doing different things); ask contributor to revise PR #12 (slower, less control over scope decision) |
| Verification strategy | Manual smoke test on Claude Code + Copilot before merge; document Cursor/OpenCode as best-effort | User has not pre-tested. Cross-platform CI is out of scope. Stage-able commits keep blast radius reversible. | Full cross-platform CI (out of scope); merge-and-fix-forward (too risky given uniformity decision); test-only the 6 broken skills (does not validate the uniformity decision) |
| Slug derivation | Slug = directory name | Simple, mechanical, unambiguous | Custom per-skill slugs (unnecessary variance) |

## Outstanding Questions

| # | Question | Impact if Wrong | Owner |
|---|----------|-----------------|-------|
| Q1 | Does Claude Code's plugin loader dedupe a `.`-separated explicit prefix the way it currently dedupes `:`-separated prefixes? (Today, `name: superpowers-ruby:compound` displays as `superpowers-ruby:compound`, not `superpowers-ruby:superpowers-ruby:compound`.) | If Claude Code does **not** dedupe with `.`: every skill would display as `superpowers-ruby:superpowers-ruby.<skill>`. The plugin would still function, but the UX is broken. Mitigation: revert to bare names plus a Copilot-specific shim. | Lucian — verify in Claude Code with one renamed skill before bulk-renaming all 34 |
| Q2 | Do Cursor and OpenCode tolerate `superpowers-ruby.<skill>` in the `name:` field without double-prefixing or rejecting? | If they reject or double-prefix: the rename breaks the plugin on those platforms. Mitigation: same as Q1 — revert and apply a per-platform shim. | Lucian — manual smoke test post-rename |
| Q3 | Should agents (`agents/code-reviewer.md`) and commands (`commands/*.md`) follow the same `superpowers-ruby.` convention for their `name:` fields? | If skills use `.` but agents/commands use a different convention: inconsistency for users. | Deferred to a follow-up — out of scope for this PR but flagged for tracking |
| Q4 | Should the hook config in `hooks/` reference the new dot-form names anywhere? | Probably not — hooks reference tool/event names, not skill names. Confirm during implementation. | Resolved during implementation by audit |
