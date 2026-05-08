# Session Q&A Log: Copilot Naming Compatibility

**Date:** 2026-05-08
**Mode:** New Feature
**Scope:** Standard
**Phases completed:** 0, 1, 2, 3, 4, 5, 6 (skipped — see notes), 7
**Outcome:** Requirements document and implementation plan produced. Plan validated and ready for implementation. PR #12 to be superseded.

---

## Questions & Answers by Phase

### Phase 0: INTAKE & ROUTE

**Q:** What's the intended namespace prefix for the renamed skills? The user typed `superplanning.<skill>` but is working in `superpowers-ruby`.
**User:** `superpowers-ruby.<skill>`
**AI position:** Correctly identified as a typo. Did not assume — asked explicitly with three concrete options before proceeding.
**Resolved:** Confirmed prefix is `superpowers-ruby.<skill>` with a dot separator.

### Phase 2: CHALLENGE & EXPLORE

**Q:** What's the actual evidence that skills need to be renamed for Copilot compatibility? (AI suspected the rename might be unnecessary because the existing `copilot-tools.md` only documents tool mappings, not name format requirements.)
**User:** Pointed to PR [#12](https://github.com/lucianghinda/superpowers-ruby/pull/12).
**AI position:** Pushed on the premise — questioned whether a 34-skill rename was necessary at all. Reading PR #12 confirmed the bug is real: Copilot's validator rejects `:` in `name:`. AI then took a position: only 6 skills are actually broken (PR #12's 5 plus `consulting-an-oracle` added later); the other 28 work everywhere; recommended fixing only the 6 + catalog references.
**Resolved:** Premise confirmed real. AI's surgical-fix recommendation surfaced as one option among three.

**Q:** How wide should this rename go? (AI recommended option: just the 6 broken skills + catalog. User chose option: all 34 skills get explicit prefix.)
**User:** All 34 skills get the explicit prefix.
**AI position:** AI recommended the surgical fix (6 skills), citing risk of double-prefixing or platform-specific loader regressions on the 28 currently-working skills. User chose the wider scope for naming uniformity.
**Resolved:** User wants uniformity across all 34. AI did not blindly accept — pushed once more on platform testing.

**Q:** Have you tested that all 34 skills with `superpowers-ruby.<skill>` names load correctly across Claude Code, Cursor, OpenCode, and Copilot? (Second push.)
**User:** Has not tested in Claude Code. Wants all skills to work the same way from a naming perspective.
**AI position:** Surfaced concrete double-prefix risk: Claude Code might display `superpowers-ruby:superpowers-ruby.brainstorming` if its dedupe logic doesn't recognize the dot-form prefix. Asked user to confirm awareness of the untested risk. After user confirmed, AI committed to the direction and added manual verification + a single-skill pilot (Unit 1) to the plan as the de-risk strategy.
**Resolved:** Direction locked: all 34 skills, with a pilot-first staging to catch any regression before bulk rollout.

**Q:** PR #12 is open and proposes a different fix (`:` → `-`, only 5 skills). How should we handle it?
**User:** Supersede with this branch + explain in close comment.
**AI position:** AI recommended this option; user agreed.
**Resolved:** Plan includes a Unit 5 step to comment on and close PR #12 when this branch's PR merges.

**Q:** Ready to proceed to Phase 3 (Define)?
**User:** Yes — draft requirements doc at `docs/plans/`.
**AI position:** Phase 2 transition checkpoint — confirmed all premise items resolved before producing artifacts.
**Resolved:** Proceeded to Phase 3.

### Phase 4: STRUCTURE — Step 4.0 Clarify

**Q:** How should the rename be staged in commits?
**User:** One commit per logical unit.
**AI position:** Recommended this option implicitly via the unit structure. User confirmed.
**Resolved:** 5 commits during implementation, one per unit.

**Q:** What's the verification gate before merging?
**User:** Claude Code + Copilot CLI manual smoke test.
**AI position:** Recommended this option. Cursor/OpenCode noted as best-effort.
**Resolved:** Manual smoke-test gate; regression detection path added to Unit 5 (release notes call out best-effort platforms and 6.6.1 hotfix path).

---

## Key Decisions

| Decision | Chosen | Phase | Rationale |
|----------|--------|-------|-----------|
| Separator character | `.` (dot) | 2 | Preserves namespace.skill visual parsing; passes Copilot regex; preferred over PR #12's `-` |
| Rename scope | All 34 skills | 2 | User chose uniformity over surgical fix despite AI recommending the latter |
| PR #12 disposition | Supersede + close with comment | 2 | Single coherent history; credits contributor |
| Commit staging | One commit per logical unit (5 commits) | 4 | Easy revert path for the most-likely regression points |
| Verification gate | Claude Code + Copilot manual smoke test | 4 | User has not pre-tested all platforms; pilot-first staging mitigates |
| Slug derivation | Slug = directory name | 4 | Mechanical, unambiguous |
| Phase 5 review depth | Combined CEO + Engineering only | 5 | Design review skipped — no UI surface to review (YAGNI) |

---

## Positions Where AI Pushed Back

| Topic | AI Position | User Response | Final Resolution |
|-------|------------|---------------|------------------|
| Premise: is this rename necessary at all? | Initially suspected unnecessary (`copilot-tools.md` documented no name-format requirement) | Pointed to PR #12 with the actual validator error | Premise confirmed real; rename proceeds |
| Scope: 6 broken skills only vs. all 34? | Recommended surgical fix (6 skills) to minimize blast radius | Chose all 34 for naming uniformity | Direction locked at 34 with pilot-first staging |
| Risk: untested cross-platform behavior | Pushed for verification before committing to all 34 | Accepted untested risk; wants uniformity | Manual smoke test + Unit 1 pilot + hotfix-revert documented |
| Quality bar violation: Unit 3 touches 28 files | Surfaced and explicitly acknowledged the >8-file rule violation rather than splitting artificially | Implicit acceptance via the commit-staging answer | Documented in plan with rationale |

---

## Phase 6 Note

Phase 6 (Deepen) was skipped: scope is Standard, but the remaining outstanding unknowns (Q1, Q2 — cross-platform loader behavior with dot-prefix names) cannot be resolved by web research. They require the actual pilot rename. Unit 1 of the implementation plan IS the resolver.
