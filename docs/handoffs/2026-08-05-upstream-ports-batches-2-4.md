---
created: 2026-08-05T10:08:18Z
branch: lg/upstream-divergence-integration
trigger: manual
restored: false
topic: upstream-ports-batches-2-4
---

# Handoff: upstream ports, Batches 2–4

## Goal

Continue porting selected fixes from `obra/superpowers` into this fork. The
review and the decisions are done and committed; Batch 1 has shipped. What
remains is Batch 2 (small, cited), Batch 3 (the brainstorm server security
hardening — the highest-value item), and Batch 4 (manual ports needing
judgment), then a PR.

## Current State

**Branch:** `lg/upstream-divergence-integration`, 7 commits ahead of `main`,
**not pushed**, no PR open. Working tree clean.

**Shipped (Batch 1):**

| Commit | Change | Upstream |
|---|---|---|
| `f74d1b6` | `.codex-plugin/plugin.json` — explicit `"hooks": {}` | #1897 |
| `5bb9a1f` | `find-polluter.sh` — path matching + empty-result guard | #2011 |
| `ed0363b` | `Ultrathink` → `Ultra-think` | #1558 |
| `2d426b4` | Two `@file.md` refs → relative markdown links | #1532, #631 |
| `7dea012` | Circle K phrase, 4× `/Users/jesse`, 3× bare `debugging` | #1531, #1122, #1601 |

Plus `9fd7d0b` (review doc) and `2beb200` (archived handoff).

Batch 1 was verified: `find-polluter.sh` was functionally tested in a throwaway
toy repo (11/11 checks, RED-then-GREEN — the test reproduces the old silent
no-op before proving the fix), `plugin.json` re-parsed as valid JSON, `bash -n`
clean, and every original defect grep returns clear.

**Not started:** Batches 2, 3, 4.

## Key Decisions

The full decision record with quoted upstream rationale is in the review doc.
The ones that still govern the remaining work:

- **Decline upstream's SDD single-reviewer consolidation (#1717)** — the PR
  author publicly corrected their own catch-rate claim (two reviewers 4/5 vs the
  new design's 3/5) and a user reported doubled token usage plus a "nag machine"
  controller. Keep this fork's two-reviewer flow; take only the separable
  hardening (#1065, #1538, #1543, #1998).
- **Keep `verification-before-completion`'s "dishonesty" line** — upstream cut it
  under an eval they themselves flagged inconclusive and low-confidence.
- **The worktree rewrite (#1121/#1124) cannot be ported** — this fork's
  `using-git-worktrees` is Rails/SQLite-specific and delegates to
  `using-sqlite-worktrees`. Take only the transferable finding: *agents anchor on
  code blocks and skip prose*.
- **Batch 2's WebSocket frame cap is a subset of Batch 3** — if Batch 3 lands in
  the same push, take the cap as part of the wholesale `scripts/` port rather
  than hand-patching `server.cjs` twice.
- **Commit granularity:** Batch 1 landed as five commits, not one, because the
  causes differ and each should be independently revertable with its own WHY.
  Continue that pattern.
- **Rationale comes from merged upstream PRs, never inference** — upstream's PR
  template requires "What problem are you trying to solve?" and "What
  alternatives did you consider?", so every claim is quotable first-hand. Cite
  the PR number in each commit body.

## Modified Files

Everything below is committed on the branch; nothing is uncommitted.

- `docs/plans/2026-08-04-upstream-divergence-review.md` (new)
- `docs/handoffs/_archive/2026-08-05-upstream-divergence-integration.md` (new)
- `.codex-plugin/plugin.json`
- `docs/testing.md`
- `skills/receiving-code-review/SKILL.md`
- `skills/systematic-debugging/{SKILL.md,find-polluter.sh,CREATION-LOG.md,root-cause-tracing.md}`
- `skills/test-driven-development/SKILL.md`
- `skills/using-git-worktrees/SKILL.md`
- `skills/using-superpowers/SKILL.md`
- `skills/writing-skills/SKILL.md`

## Failed Approaches

- **`tests/opencode/run-tests.sh` is red on clean `main`** — `test-plugin-loading.sh`
  runs `cp .../lib` and this repo has no `lib/` directory. Confirmed pre-existing
  by stashing and re-running. A red suite there is **not** a signal that a port
  broke something. Fix separately or ignore.
- **Ruby 2.6 is the active system Ruby** (`ruby -v` → 2.6.10). Endless method
  definitions (`def f(x) = ...`) fail to parse. Use classic `def`/`end` in
  throwaway scripts, or activate a modern Ruby via chruby first.
- **zsh mangles `$VAR:path` in `git show`** — the `:` triggers modifier parsing
  ("bad substitution"). Use `${VAR}:path`.
- **`grep --include=*.md` unquoted in zsh** fails with "no matches found". Quote
  the glob or pass explicit directories.
- **shellcheck is not installed on this machine** — upstream's shellcheck gate on
  `find-polluter.sh` was not reproduced. Install it before touching more shell.

## Files to Read

- `docs/plans/2026-08-04-upstream-divergence-review.md` — **read first.** Tiered
  assessment, per-item upstream rationale with quotes, suggested order,
  verification boundary, and Appendix A (all 291 upstream commits classified).
- `docs/handoffs/_archive/2026-08-05-upstream-divergence-integration.md` — how
  Batch 1 was executed and verified.

## Next Steps

1. **Batch 2 — small, cited, low risk:**
   - `.opencode/plugins/superpowers.js` — `getBootstrapContent()` is called at
     line 84 on *every* `messages.transform`, doing a full `readFileSync` +
     frontmatter parse + template build **before** the already-injected
     early-return at line 89. Hoist the injection check above the call, or cache
     the string at module level. Preserve this fork's handoff/compaction hooks.
     (issue #1202)
   - `skills/brainstorming/scripts/server.cjs` — 10 MiB `MAX_FRAME_PAYLOAD_BYTES`
     rejected from the frame header alone, before `Buffer.alloc(payloadLen)` at
     line 66 (length read from the client at line 56). **Skip if doing Batch 3
     immediately** — see Key Decisions. (#1555)
   - Port `dispatching-parallel-agents` and `receiving-code-review` via
     `git checkout upstream/main -- skills/<name>/SKILL.md`. Both were
     byte-identical to the merge base. **Verify, do not assume:**
     `receiving-code-review` now carries the Circle K fix from `7dea012` and
     upstream's copy has the same replacement, so it should overwrite cleanly —
     diff it before committing.

2. **Batch 3 — brainstorm companion hardening (#1720), land as its own commit:**
   `skills/brainstorming/scripts/server.cjs` is the 338-line pre-hardening
   version (upstream's is 723). No authentication, any origin accepted; on a
   `--host 0.0.0.0` bind any routable host can read screens and inject fake
   `click` events into `state/events`, which the agent consumes as the user's
   next selection — prompt injection into a live session. Also: null-payload
   crash (#1504), `._*.html` resource-fork files served as mockups (#950),
   30-minute silent idle death (`server.cjs:247`, #1237). The `scripts/` dir has
   the same 5 files as upstream, so
   `git checkout upstream/main -- skills/brainstorming/scripts/` is close to
   viable; then re-apply this fork's `SKILL.md` wiring and Ruby-specific prose.
   **Bring upstream's `tests/brainstorm-server` (12 files) with it and actually
   run them.**

3. **Batch 4 — manual ports requiring judgment:**
   - **Fix `skills/finishing-a-development-branch/SKILL.md`** (confirmed live bug,
     worse here than upstream's): line 143 runs
     `git worktree list | grep $(git branch --show-current)`, but Option 1
     (line 73) and Option 4 (line 131) already did `git checkout <base-branch>`,
     so it greps the *base* branch and matches the main worktree. Option 1's
     `git branch -d` at line 85 also runs while the worktree is still attached,
     which git refuses — Option 1 is broken end to end. Capture the worktree path
     in Step 2 before any `cd`; remove the worktree before deleting the branch;
     drop the hardcoded `gh pr create` (line 97); demote discard off the menu.
     (#1933)
   - Add the `writing-skills` form-selection section (+33 lines, additive; no
     existing tuned content modified). (#1741)
   - SDD subset: RED/GREEN evidence fields in `implementer-prompt.md` (#1065),
     reviewer diff scoping (#1538), read-only reviewers (#1543), and a round cap
     at `skills/subagent-driven-development/SKILL.md:258`, which currently reads
     `- Repeat until approved` with no limit (#1998).
   - Merge `agents/code-reviewer.md` (48 lines, generic persona) into
     `skills/requesting-code-review/code-reviewer.md` (153 lines, Ruby/Rails
     template, different placeholders) and delete `agents/`. Drift is confirmed
     real. (#1299)
   - Delete `commands/{brainstorm,execute-plan,write-plan}.md` — three pure
     deprecation stubs, deprecated since 5.0.0, fork is at 7.4.0. (#1188)
   - Move sole-carrier requirements to their point of use **before** pruning
     Integration sections: the worktree prerequisite for `executing-plans` and
     SDD, and systematic-debugging's verification-before-completion handoff, are
     stated nowhere else today. (#1932)

4. **Before the PR:** consider a `superpowers-ruby:requesting-code-review` pass
   over the branch, then push and open the PR against
   `lucianghinda/superpowers-ruby` (never `obra/superpowers`).

5. **Housekeeping, unrelated to the ports:** fix the broken `tests/opencode`
   runner; delete the duplicated sentence at line 712 of the review doc.

## Open Questions

- **Does a version bump belong with these ports, and at what point?** Project
  convention touches 9 files: `scripts/bump-version.sh` handles 6 JSON
  manifests; `CHANGELOG.md`, `RELEASE-NOTES.md`, and the `#vX.Y.Z` pin in
  `.opencode/INSTALL.md` are manual (grep all pins — they drift). Not done for
  Batch 1. Likely wants to happen once, after the last batch lands.
- **One PR or several?** Batches 2–4 could join this branch or get their own.
  Batch 3 is large and security-relevant; splitting it out would make it easier
  to review and revert.
- **Does this fork have Windows users?** Two real gaps only matter if so:
  `hooks/hooks.json` lacks `"shell": "bash"` on the SessionStart registration
  (#1993), and `hooks/hooks-cursor.json` still calls `./hooks/session-start`
  directly rather than `./hooks/run-hook.cmd session-start` (#1054).
- **Keep `~/.config/superpowers/worktrees`?** Still offered at
  `skills/using-git-worktrees/SKILL.md:71`. Upstream removed the user-global
  fallback (#1476) as confusing; this fork may want a stable cross-project
  location. Decide before touching the Rails/SQLite worktree skill.
- **Is `gh` a deliberate hard assumption?** If this fork is GitHub-only forever,
  dropping the hardcoded `gh pr create` is portability polish rather than a fix.
  The sequencing bug in that same skill must be fixed either way.
