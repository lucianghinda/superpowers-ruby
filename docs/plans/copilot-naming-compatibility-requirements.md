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

This refactor takes a different position: instead of the surgical fix, we make the naming **uniform across all 34 skills** by setting every `name:` field to `superpowers-ruby.<skill-slug>` using a dot, and by treating that dot form as the canonical executable skill identifier in live docs, tests, hooks, and skill cross-references. The dot is preferred over a hyphen because it visually preserves the namespace–skill boundary (`superpowers-ruby.compound` parses obviously as plugin + skill, while `superpowers-ruby-compound` reads as a single hyphenated token).

The user has explicitly accepted that this change has not been tested across Claude Code, Cursor, and OpenCode and may surface platform-specific loader behavior — manual verification is part of the implementation plan.

## Requirements

| ID | Requirement | Priority | Notes |
|----|-------------|----------|-------|
| R1 | Every SKILL.md frontmatter must declare `name: superpowers-ruby.<skill-slug>` | Must Have | All 34 skills under `skills/`. Slug must match the directory name. |
| R2 | All 34 skills must load successfully under Copilot CLI without validator errors | Must Have | This is the originating bug from PR #12. Verified by running `copilot` and listing skills. |
| R3 | All 34 skills must remain invokable from Claude Code via the Skill tool using the canonical dot-form skill identifier | Must Have | Verified by invoking renamed skills as `superpowers-ruby.<skill-slug>` and by `/skills` listing showing each skill exactly once with a sane display name (no double-prefix like `superpowers-ruby:superpowers-ruby.<x>`). Platform-native display separators may differ, but executable references in this repo should use dot form. |
| R4 | The skill catalog in `skills/using-superpowers/SKILL.md` must reference each skill as `superpowers-ruby.<skill-slug>` | Must Have | Currently 28 entries use the colon form. The catalog teaches users how to invoke skills, so it must match the `name:` declared in the frontmatter. |
| R5 | Active executable skill references must use `superpowers-ruby.<skill-slug>` consistently | Must Have | Audit live instructions and tests for `superpowers-ruby:<x>` and legacy `superpowers:<x>` references to actual skill slugs. Scope: `skills/`, `commands/`, `agents/`, `hooks/`, `tests/`, top-level live docs, and current implementation docs. Historical release/changelog entries may keep old names when explicitly describing old behavior. Agent names such as `superpowers:code-reviewer` are out of scope unless they become skill references. |
| R6 | PR [#12](https://github.com/lucianghinda/superpowers-ruby/pull/12) must be closed with a comment crediting the contributor and explaining why this branch supersedes it | Must Have | Maintains contributor good will; provides historical record of the design choice. |
| R7 | A CHANGELOG/RELEASE-NOTES entry describing the rename must be added, following the format of existing entries | Should Have | Existing entries: see `RELEASE-NOTES.md` and `CHANGELOG.md`. Note: this is a user-visible naming change. |
| R8 | The plugin version must be bumped per `.version-bump.json` conventions | Should Have | Current version: 6.5.0. This is a behavior-preserving naming change that fixes a Copilot bug — likely 6.6.0 (minor). All 5 versioned manifests must move in lockstep (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.cursor-plugin/plugin.json`, `package.json`, `gemini-extension.json`). `.opencode/package.json` has no version field and must be explicitly checked but not bumped. |
| R9 | The 34 skills should continue to load on OpenCode before merge and Cursor as best effort | Should Have | OpenCode has existing tests/references that assert colon names, so run its smoke tests before merge and update them to dot form. Cursor remains manual best effort; if a regression is found post-merge, a hotfix (revert to bare names for working skills) must be ready. |
| R10 | Top-level docs (`README.md`) that reference skill names should be audited and updated for consistency where the dot form makes sense | Nice to Have | If references are abstract ("the brainstorming skill"), no change needed. Only update if the doc shows the literal invocation form. |

## Success Criteria

The rename is successful when **all** of the following are observable:

1. `copilot /skills` (or equivalent listing) shows all 34 superpowers-ruby skills without any of the historical "Skill name must contain only..." errors.
2. In Claude Code, invoking representative renamed skills by `superpowers-ruby.<skill-slug>` succeeds, and `/skills` (or the system reminder skills list) shows each renamed skill exactly once with no double-prefixed display strings.
3. Invoking any of the 6 originally-broken skills (`compound`, `compound-refresh`, `handoff`, `handoff-list`, `handoff-resume`, `consulting-an-oracle`) by its new dot-form name in Copilot succeeds and the skill content loads.
4. OpenCode's skill-loading smoke tests are updated to dot form and pass, or any non-runnable OpenCode check is explicitly documented before merge.
5. A repo-wide audit for `superpowers-ruby:` and legacy `superpowers:` references returns only intentional historical entries and non-skill identifiers such as `superpowers:code-reviewer`.
6. PR #12 is closed with a comment that names this branch's PR.
7. The version bump and CHANGELOG entry exist in the merge commit.

## Scope Boundaries

**In scope:**
- The `name:` field in all 34 `skills/<skill>/SKILL.md` files
- The catalog table in `skills/using-superpowers/SKILL.md`
- Active executable skill references inside `skills/`, `commands/`, `agents/`, `hooks/`, `tests/`, top-level live docs, and current implementation docs that use `superpowers-ruby:` or legacy `superpowers:` for actual skill slugs
- The plugin version bump across all manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.cursor-plugin/plugin.json`, `package.json`, `gemini-extension.json`)
- Explicitly checking `.opencode/package.json` and documenting that it has no version field to bump
- A `RELEASE-NOTES.md` and/or `CHANGELOG.md` entry
- A close comment on PR #12

**Out of scope:**
- Renaming any skill folder under `skills/` (folder names are unchanged)
- Renaming any agent under `agents/` (only `code-reviewer.md` exists; no compatibility issue)
- Renaming any command under `commands/`
- Modifying hooks or scripts except to update literal active skill-name references
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
| Verification strategy | Manual smoke test on Claude Code + Copilot before merge; update and run OpenCode smoke tests before merge; document Cursor as best-effort | User has not pre-tested all platforms. OpenCode has repo-local tests that assert the old names, so those need to move with the rename. Cross-platform CI is out of scope. Stage-able commits keep blast radius reversible. | Full cross-platform CI (out of scope); merge-and-fix-forward (too risky given uniformity decision); test-only the 6 broken skills (does not validate the uniformity decision) |
| Slug derivation | Slug = directory name | Simple, mechanical, unambiguous | Custom per-skill slugs (unnecessary variance) |

## Outstanding Questions

| # | Question | Impact if Wrong | Owner |
|---|----------|-----------------|-------|
| Q1 | Does Claude Code's plugin loader dedupe a `.`-separated explicit prefix the way it currently dedupes `:`-separated prefixes? (Today, `name: superpowers-ruby:compound` displays as `superpowers-ruby:compound`, not `superpowers-ruby:superpowers-ruby:compound`.) | If Claude Code does **not** dedupe with `.`: every skill would display as `superpowers-ruby:superpowers-ruby.<skill>`. The plugin would still function, but the UX is broken. Mitigation: revert to bare names plus a Copilot-specific shim. | Lucian — verify in Claude Code with one renamed skill before bulk-renaming all 34 |
| Q2 | Do Cursor and OpenCode tolerate `superpowers-ruby.<skill>` in the `name:` field without double-prefixing or rejecting? | If they reject or double-prefix: the rename breaks the plugin on those platforms. Mitigation: same as Q1 — revert and apply a per-platform shim. | Lucian — OpenCode smoke test before merge; Cursor manual smoke test best effort |
| Q3 | Should agents (`agents/code-reviewer.md`) and commands (`commands/*.md`) follow the same `superpowers-ruby.` convention for their `name:` fields? | If skills use `.` but agents/commands use a different convention: inconsistency for users. | Deferred to a follow-up — out of scope for this PR but flagged for tracking |
| Q4 | Which hook/test/doc references are active executable skill names versus historical examples or non-skill identifiers? | If the audit is too narrow, users and tests will still teach or assert the old execution names after the rename. If it is too broad, historical notes and agent names may be mangled. | Resolved during Unit 4 by repo-wide audit and manual classification |
