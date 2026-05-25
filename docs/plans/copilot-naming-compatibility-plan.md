# Copilot Naming Compatibility — Implementation Plan

**Version:** 1.0
**Status:** Draft
**Date:** 2026-05-08
**Branch:** `lg/rename-compatibility`
**Requirements:** [`copilot-naming-compatibility-requirements.md`](./copilot-naming-compatibility-requirements.md)
**Supersedes:** PR [#12](https://github.com/lucianghinda/superpowers-ruby/pull/12)

## Overview

Rename every skill's `name:` frontmatter field to `superpowers-ruby.<skill-slug>` so that:

- The 6 currently-broken skills load on Copilot CLI (R2)
- All 34 skills share a uniform `namespace.skill` executable identifier in live docs, tests, hooks, and cross-references (R1, R4, R5)
- No platform regresses on Claude Code, Cursor, OpenCode (R3, R9)

**Staging:** One commit per logical unit (5 commits). The first unit is a single-skill pilot specifically to de-risk the cross-platform behavior **before** the bulk rename.

## Architecture (One Page)

```
┌─────────────────────────────────────────────────────────────────────┐
│  superpowers-ruby plugin                                            │
│                                                                     │
│  .claude-plugin/plugin.json ──┐                                     │
│  .cursor-plugin/plugin.json ──┼── declares plugin name              │
│  package.json (opencode) ─────┤    (used by loaders to              │
│  gemini-extension.json ───────┘    auto-namespace skills)           │
│                                                                     │
│  skills/<slug>/SKILL.md       ── frontmatter declares `name:`       │
│                                                                     │
│  Loader behavior (current):                                         │
│    Claude Code  : <plugin>:<name>     (colon)                       │
│    OpenCode     : <plugin>/<name>     (slash)                       │
│    Cursor       : <plugin>:<name>     (assumed; same as CC)         │
│    Copilot CLI  : <plugin>.<name>     (dot — REJECTS `:` in name)   │
│                                                                     │
│  This plan: change every `name:` field to `superpowers-ruby.<slug>` │
│  and rely on each loader to dedupe the explicit prefix (verified in │
│  Unit 1 before bulk rename).                                        │
└─────────────────────────────────────────────────────────────────────┘
```

## Dependency Graph

```
Unit 1 (Pilot: handoff)
       │  ── verifies cross-platform behavior; DAG cuts here on regression
       ▼
Unit 2 (Remaining broken: compound, compound-refresh, handoff-list, handoff-resume, consulting-an-oracle)
       │
       ▼
Unit 3 (Bulk uniformity: 28 working skills get explicit prefix)
       │
       ▼
Unit 4 (Canonical execution-name audit: catalog, live docs, hooks, tests)
       │
       ▼
Unit 5 (Version bump + CHANGELOG/RELEASE-NOTES + supersede PR #12)
```

Cycle check: linear, acyclic. Each unit consumes the previous unit's verification.

---

## Unit 1: Pilot rename — single skill (`handoff`)

**Goal:** Rename one skill's `name:` field to `superpowers-ruby.handoff` and verify cross-platform behavior before touching the other 33 skills.

**Requirements trace:** R1, R2, R3 (verified in pilot scope before bulk rollout)

**Dependencies:** None (entry point)

**Files:**
- `skills/handoff/SKILL.md` — change frontmatter `name: superpowers-ruby:handoff` → `name: superpowers-ruby.handoff`

**Approach:**
1. Edit one line in `skills/handoff/SKILL.md` frontmatter.
2. Verify in Claude Code: invoke the Skill tool with the new dot-form name (`superpowers-ruby.handoff`); observe the `/skills` listing (or system reminder) shows the skill **once** with no double-prefix string like `superpowers-ruby:superpowers-ruby.handoff`.
3. Verify locally in Copilot CLI: install the plugin from this branch, run skill listing, confirm `handoff` no longer surfaces the validator error.
4. Verify locally in OpenCode with a targeted pilot smoke test if the environment is available: list/load `superpowers-ruby.handoff` and confirm no rejection or double-prefix display. If OpenCode cannot run locally, document the exact blocker and keep the full OpenCode smoke test as a pre-merge gate in Unit 4.
5. If Claude Code, Copilot, or an available OpenCode pilot double-prefixes or rejects: **STOP**. Revert this unit, escalate to user, and consider per-platform shim approach instead. Do not proceed to Unit 2.

**Patterns:** Follows the existing frontmatter format in all 6 currently-prefixed skills (`name: superpowers-ruby:<slug>`). Only the separator changes.

**Verification scenarios:**
- [ ] Claude Code can invoke the skill as `superpowers-ruby.handoff`.
- [ ] Claude Code skills list shows the skill once, with no double-prefix artifact. The exact display separator may remain platform-native; the executable identifier in repo docs/tests is dot form.
- [ ] Copilot CLI loads the plugin with no `Skill name must contain only...` error against `handoff`.
- [ ] OpenCode targeted pilot loads `superpowers-ruby.handoff`, or a local environment blocker is documented and Unit 4 remains the pre-merge OpenCode gate.
- [ ] Skill content is invokable from each tested platform and produces the existing handoff behavior unchanged.
- [ ] `git diff skills/handoff/SKILL.md` shows exactly one line changed (the `name:` field).

**Verification (concrete):**
- Run `grep "^name:" skills/handoff/SKILL.md` → must return `name: superpowers-ruby.handoff`.
- In Claude Code, the system reminder skills list shows the renamed skill with no `superpowers-ruby:superpowers-ruby.<…>` artifact.

**Planning-time unknowns:** Q1 and the OpenCode portion of Q2 from requirements doc. **Resolve Before Planning** — Unit 1 is the first resolver, and Unit 4 remains the full OpenCode pre-merge gate after test references are updated. Cursor remains best-effort manual smoke testing.

**Commit:** `fix(handoff): use dot separator in skill name for Copilot compatibility`

---

## Unit 2: Rename remaining broken skills

**Goal:** Apply the same rename to the 5 other skills that currently fail Copilot's validator.

**Requirements trace:** R1, R2

**Dependencies:** Unit 1 (must verify cross-platform green)

**Files:**
- `skills/compound/SKILL.md` — `name: superpowers-ruby:compound` → `name: superpowers-ruby.compound`
- `skills/compound-refresh/SKILL.md` — same swap
- `skills/handoff-list/SKILL.md` — same swap
- `skills/handoff-resume/SKILL.md` — same swap
- `skills/consulting-an-oracle/SKILL.md` — same swap

**Approach:** Mechanical: in each file's frontmatter, replace `superpowers-ruby:` with `superpowers-ruby.` in the `name:` line. Do not touch any other content (descriptions, body, scripts).

**Patterns:** Identical pattern to Unit 1.

**Verification scenarios:**
- [ ] All 5 files have `name: superpowers-ruby.<slug>` in their frontmatter.
- [ ] `grep -c "^name: superpowers-ruby:" skills/*/SKILL.md` returns 0 (no remaining colon-prefixed names anywhere).
- [ ] Copilot CLI's previous failed-skill list is now empty (re-run the same listing that produced the error in PR #12).
- [ ] Claude Code can invoke each of the 5 skills with no display anomaly.
- [ ] No file other than the 5 listed has changed (`git diff --name-only` is exact).

**Verification (concrete):**
- `grep "^name:" skills/{compound,compound-refresh,handoff-list,handoff-resume,consulting-an-oracle}/SKILL.md` → all show `name: superpowers-ruby.<slug>`.

**Planning-time unknowns:** None — Unit 1 resolved them.

**Commit:** `fix(skills): rename remaining broken skills to dot-prefix form`

---

## Unit 3: Standardize bare-name skills to dot-prefix form

**Goal:** Add `superpowers-ruby.` prefix to the 28 currently-bare-named skills so all 34 skills share one uniform name format.

**Requirements trace:** R1 (uniformity)

**Dependencies:** Unit 2 (so the broken skills are already fixed independently — if Unit 3 needs to revert, the urgent Copilot fix stays in place)

**Files (28 total — listed for traceability):**

*Process & Workflow (11):*
- `skills/brainstorming/SKILL.md`
- `skills/test-driven-development/SKILL.md`
- `skills/systematic-debugging/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/executing-plans/SKILL.md`
- `skills/dispatching-parallel-agents/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `skills/finishing-a-development-branch/SKILL.md`
- `skills/using-git-worktrees/SKILL.md`
- `skills/using-sqlite-worktrees/SKILL.md`

*Ruby & Rails (6):*
- `skills/ruby/SKILL.md`
- `skills/rails-guides/SKILL.md`
- `skills/rails-upgrade/SKILL.md`
- `skills/37signals-style/SKILL.md`
- `skills/ruby-commit-message/SKILL.md`
- `skills/sandi-metz-rules/SKILL.md`

*Hotwire & Stimulus (6):*
- `skills/hwc-stimulus-fundamentals/SKILL.md`
- `skills/hwc-navigation-content/SKILL.md`
- `skills/hwc-forms-validation/SKILL.md`
- `skills/hwc-ux-feedback/SKILL.md`
- `skills/hwc-realtime-streaming/SKILL.md`
- `skills/hwc-media-content/SKILL.md`

*Security + Review + Meta (5):*
- `skills/brakeman/SKILL.md`
- `skills/requesting-code-review/SKILL.md`
- `skills/receiving-code-review/SKILL.md`
- `skills/writing-skills/SKILL.md`
- `skills/using-superpowers/SKILL.md`

**Approach:**
1. For each file, replace the bare frontmatter line `name: <slug>` with `name: superpowers-ruby.<slug>` where `<slug>` matches the directory name.
2. Touch nothing else. Do not change descriptions, body, scripts, or references in this unit (those are Unit 4).
3. Verify by `grep "^name:" skills/*/SKILL.md` — every entry should now read `name: superpowers-ruby.<slug>`.

**Patterns:** Same single-line edit pattern, applied 28 times.

**Verification scenarios:**
- [ ] All 34 SKILL.md files (Units 1+2+3) have `name: superpowers-ruby.<slug>`.
- [ ] No SKILL.md has a bare `name: <slug>` without the prefix.
- [ ] Claude Code skills list shows all 34 skills exactly once with no double-prefix.
- [ ] Copilot CLI loads all 34 skills with no validator errors.
- [ ] No file outside `skills/*/SKILL.md` has changed.

**Verification (concrete):**
- `grep -L "^name: superpowers-ruby\." skills/*/SKILL.md` → empty (no SKILL.md is missing the prefix).
- `grep "^name:" skills/*/SKILL.md | grep -v "superpowers-ruby\."` → empty (no SKILL.md has any other form of `name:`).

**Quality bar exception:** This unit touches 28 files, exceeding the >8-file guideline. Rationale: 28 mechanically identical single-line edits, all in the same trivially-reviewable form. The user explicitly chose "one commit per logical unit", and "uniformity refactor" is the logical unit. Splitting into categorical sub-units would create artificial review boundaries with no information value (each sub-commit would still be the same one-line pattern). Accepted with explicit acknowledgment.

**Planning-time unknowns:** None.

**Commit:** `refactor(skills): standardize all skill names to superpowers-ruby.<slug> form`

---

## Unit 4: Update canonical execution-name references

**Goal:** Update active executable skill references to the canonical `superpowers-ruby.<skill>` form so live docs, tests, hooks, and skill cross-references all teach and verify one naming convention.

**Requirements trace:** R4, R5

**Dependencies:** Unit 3 (frontmatter is now the source of truth that body references must match)

**Files:**
- `skills/using-superpowers/SKILL.md` — the catalog table (~28 entries, lines ~120–188 per current Read) plus any prose mentions of skill names
- Any other `skills/**/*.md` whose body text contains `superpowers-ruby:` or legacy `superpowers:` references to actual skill slugs
- Any `commands/*.md` or `agents/*.md` files containing active executable skill references
- `hooks/*` entries that embed literal skill names, especially `hooks/session-start`
- `tests/` references that assert or prompt with old skill names, especially OpenCode and Claude Code integration tests
- Top-level live docs (`README.md`, current setup docs) and current implementation docs that show literal invocation names
- `CHANGELOG.md` and `RELEASE-NOTES.md` only for new/current 6.6.0 entries or live instructions; keep historical entries intact when they describe prior behavior

**Approach:**
1. Run `grep -rnE "superpowers-ruby:|superpowers:" skills/ commands/ agents/ hooks/ tests/ README.md docs/ CHANGELOG.md RELEASE-NOTES.md` to enumerate old-form skill references.
2. Build a short classification list before editing:
   - **Update:** active executable references to one of the 34 skill slugs, e.g. `superpowers-ruby:brainstorming`, `/superpowers-ruby:handoff`, `superpowers:executing-plans`.
   - **Keep:** non-skill identifiers such as `superpowers:code-reviewer` agent references.
   - **Keep:** historical changelog/release-note entries and old design docs that intentionally describe earlier behavior.
3. For every **Update** match, replace the skill identifier with `superpowers-ruby.<slug>`. For slash-command examples, prefer the canonical skill identifier without a slash unless the text is explicitly about platform-native slash commands.
4. Update OpenCode/Claude Code tests that assert or prompt with old skill names so they use dot form and still test the same behavior.
5. Confirm the audit command returns only **Keep** entries, and document those intentional leftovers in the Unit 4 commit message or PR body.

**Patterns:** Match Unit 1–3's separator decision in all live executable references. Do not blind-replace `superpowers:` because some matches are agent names or historical docs, not skills.

**Verification scenarios:**
- [ ] The catalog table in `using-superpowers/SKILL.md` shows every skill as `superpowers-ruby.<slug>`.
- [ ] No live instruction, hook, or test references a skill via the old colon form.
- [ ] OpenCode smoke tests and any skill-name assertions are updated to dot form.
- [ ] No prose was mangled by an over-eager replacement (review the diff manually for grammatical colons).
- [ ] Markdown table formatting is preserved after edits (column alignment, no broken pipes).

**Verification (concrete):**
- `grep -rnE "superpowers-ruby:|superpowers:" skills/ commands/ agents/ hooks/ tests/ README.md docs/ CHANGELOG.md RELEASE-NOTES.md` → returns only documented intentional leftovers: historical entries, legacy design docs, or non-skill identifiers such as `superpowers:code-reviewer`.
- `grep -c "superpowers-ruby\." skills/using-superpowers/SKILL.md` → equal to the count of skills in the catalog (28 for the table, possibly more for inline mentions).
- OpenCode smoke test command from the repo's test docs succeeds, or the reason it could not be run is documented before merge.

**Quality bar exception:** This unit may touch more than 8 files because the old executable names appear in tests, hooks, and live instructions. The work remains mechanical but must be classified manually before replacement to avoid changing historical notes or non-skill agent identifiers.

**Planning-time unknowns:** Which `superpowers:` matches are active skill references versus historical notes or agent identifiers. **Deferred to Planning** — resolved by the classification audit at the start of this unit.

**Commit:** `docs(skills): standardize live skill references to dot-form`

---

## Unit 5: Version bump + release notes + supersede PR #12

**Goal:** Bump the plugin version across all manifests, add release-notes/changelog entries, and prepare the comment that closes PR #12 when this branch's PR merges.

**Requirements trace:** R6, R7, R8

**Dependencies:** Unit 4 (release notes can only describe a complete change set)

**Files:**
- `.claude-plugin/plugin.json` — `"version": "6.5.0"` → `"version": "6.6.0"`
- `.claude-plugin/marketplace.json` — same bump
- `.cursor-plugin/plugin.json` — same bump
- `package.json` — same bump (used by OpenCode)
- `gemini-extension.json` — same bump
- `.opencode/package.json` — inspect only; no version field, so no bump expected
- `CHANGELOG.md` — new entry at the top (TODO(human) — see below)
- `RELEASE-NOTES.md` — new entry at the top (TODO(human) — see below)

**Approach:**
1. Bump version to 6.6.0 in all 5 versioned manifest files. Follow `.version-bump.json` conventions; verify by `grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json .cursor-plugin/plugin.json package.json gemini-extension.json` — all five must read `"6.6.0"`.
2. Inspect `.opencode/package.json` and confirm it has no plugin version field. Do not add a version field just for symmetry.
3. Add a `## [6.6.0] - 2026-05-08` section to the top of `CHANGELOG.md` describing the rename. Voice and emphasis: the user has written every prior entry — the assistant **leaves a `TODO(human)` placeholder** in this file for the user to write the entry in their own voice (see "Learn by Doing" below).
4. Add a corresponding entry to `RELEASE-NOTES.md` (also `TODO(human)`).
5. After the PR is opened: post a comment on PR [#12](https://github.com/lucianghinda/superpowers-ruby/pull/12) that:
   - Credits the contributor's analysis
   - Explains the choice of `.` over `-`
   - Notes the expanded scope (uniformity across all 34 skills)
   - Links to this branch's PR
   - Closes the PR (as part of the merge or by hand once this branch's PR is merged)

**Patterns:** Existing CHANGELOG.md and RELEASE-NOTES.md entries; existing version-bump commits (e.g., `313a08e chore: bump version to 6.5.0 for consulting-an-oracle skill`).

**Verification scenarios:**
- [ ] All 5 manifests show `"6.6.0"`.
- [ ] `.opencode/package.json` was checked and still has no plugin version field.
- [ ] CHANGELOG.md and RELEASE-NOTES.md have new top-of-file entries dated 2026-05-08 for 6.6.0.
- [ ] No `TODO(human)` markers remain in the committed files (the user resolves them before the final commit).
- [ ] PR #12 comment is drafted (saved as a `.git-comment` artifact or similar) ready to post when this branch's PR merges.

**Verification (concrete):**
- `grep '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json .cursor-plugin/plugin.json package.json gemini-extension.json | grep -v "6.6.0"` → empty.

**Planning-time unknowns:** Exact wording of CHANGELOG/RELEASE-NOTES entries — **Deferred to Planning**. Resolved by the user via the `TODO(human)` block (see Learn by Doing below).

**Commit:** `chore: bump version to 6.6.0 for copilot-naming-compatibility`

---

## Quality Bar Checklist

- [x] Every unit traces to at least one requirement
- [x] Dependencies form a DAG (Unit 1 → 2 → 3 → 4 → 5)
- [x] Every unit has at least 3 verification scenarios
- [x] No unit touches >8 files **EXCEPT Unit 3** (28 files; rationale documented in Unit 3) and potentially Unit 4 (repo-wide live-reference audit; rationale documented in Unit 4)
- [x] No unit introduces >2 new abstractions (no abstractions are introduced; this is a pure rename)
- [x] Every planning-time unknown is classified (Q1, Q2 → Unit 1 resolver; Q3 deferred to follow-up; Q4 resolved by Unit 4 audit)
- [x] Handoff completeness: an engineer reading this plan does not need to invent any product behavior. The only thing left is the CHANGELOG/RELEASE-NOTES wording, which is intentionally a `TODO(human)` for voice/style reasons.

## Open Risks (carry from requirements doc Q1, Q2)

- **R1 (Q1):** Claude Code's behavior with dot-prefix `name:` field is unverified. **Mitigation:** Unit 1 is a single-skill pilot specifically to test this before bulk rollout.
- **R2 (Q2):** Cursor and OpenCode loader behavior is unverified. **Mitigation:** Same pilot; OpenCode smoke tests are updated and run before merge; Cursor remains best-effort manual smoke testing; a hotfix-revert path exists per unit.

## Hotfix-Revert Strategy

If Unit 3 lands and a regression is detected on Cursor or OpenCode post-merge: revert Unit 3's commit cleanly (it touches only 28 SKILL.md files). The 6 originally-broken skills (Units 1+2) remain fixed for Copilot, and the 28 working skills return to their previous bare-name form. This satisfies R2 (the original Copilot bug) at the cost of R1 (uniformity).

## Regression Detection (Post-Merge)

Because Cursor is **best-effort** (the user has not pre-tested it), the release-notes entry in Unit 5 must include a "Please report regressions" line that names Cursor explicitly. OpenCode gets a pre-merge smoke test because this repo already has OpenCode checks that assert the old colon names. Path: when a regression is reported, apply the Hotfix-Revert Strategy on Unit 3 and ship a 6.6.1.

## Phase 5 Validation Summary

Reviews applied: combined CEO + Engineering. Design Review skipped (no UI surface). Findings:

- **F1 (P0, revised):** Auditing only `agents/code-reviewer.md` and `commands/*.md` was too narrow for the user's uniform execution-name goal. Unit 4 now audits live skill references across skills, commands, agents, hooks, tests, top-level docs, and current implementation docs, while preserving historical notes and non-skill agent identifiers.
- **F2 (P1, autofixed):** Replaced fragile `grep -c | grep -v ":1$"` verification with `grep -L` form (Unit 3).
- **F3 (P1, autofixed):** Added Regression Detection section pointing at Cursor and naming the 6.6.1 hotfix path; OpenCode moved into pre-merge smoke testing because repo tests reference old names.

No P0/P1 unresolved. Gate 5 → 6 satisfied.
