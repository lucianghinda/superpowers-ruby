---
created: 2026-08-05T03:47:08Z
branch: lg/upstream-divergence-integration
trigger: manual
restored: true
restored_at: 2026-08-05T08:29:14Z
topic: upstream-divergence-integration
---

# Handoff: upstream divergence review → integration batches

> **Archived 2026-08-05.** Batch 1 shipped in this session. Batches 2–4 are
> still open; pick them up from the review document listed under Files to Read.

## Goal

Review everything that landed in `obra/superpowers` since this fork diverged
(merge base `8ea3981`, 2026-03-19, ≈ upstream v5.0.5), decide what is worth
porting into `superpowers-ruby` v7.4.0, and record the *why* for each proposal
sourced from the merged upstream PR discussion rather than guessed.

## Current State

**Done — review:**
- Full triage of the 291-commit upstream delta / 100 merged PRs since divergence
- Review document at `docs/plans/2026-08-04-upstream-divergence-review.md`
  (1172 lines), committed in `9fd7d0b`
- Two independent reviewers covered the delta: Claude (PR-rationale depth) and
  Codex (commit-ledger completeness + harness manifests). Codex merged its
  findings into the same file rather than writing a separate doc.
- Every fork-state claim was verified by grep against the working tree

**Done — Batch 1, all committed on `lg/upstream-divergence-integration`:**

| Commit | Change | Upstream |
|---|---|---|
| `f74d1b6` | `.codex-plugin/plugin.json` — explicit `"hooks": {}` | #1897 |
| `5bb9a1f` | `find-polluter.sh` — path matching + empty-result guard | #2011 |
| `ed0363b` | `Ultrathink` → `Ultra-think` | #1558 |
| `2d426b4` | Two `@file.md` refs → relative markdown links | #1532, #631 |
| `7dea012` | Circle K phrase, 4× `/Users/jesse`, 3× bare `debugging` | #1531, #1122, #1601 |

**Batch 1 verification:**
- `find-polluter.sh` functionally tested in a throwaway toy repo: 11/11 checks.
  The test first reproduces the old silent no-op ("Found 1 test files", exit 0,
  polluter never run), then proves the fix counts all three test files, bisects
  to the polluter, reports 0 honestly on no match, and accepts the pattern with
  or without a leading `./`. The test script was scratch-only and not kept.
- `.codex-plugin/plugin.json` re-parsed as valid JSON with the `hooks` key set
- `bash -n` clean on `find-polluter.sh`; shellcheck is not installed on this
  machine, so upstream's shellcheck pass was not repeated
- All original defect greps return clear

**Not started:** Batches 2, 3, and 4. Nothing else in the tree is modified.

**Known doc defect (unfixed):** line 712 of the review doc duplicates the
sentence already wrapped at lines 709–710 ("That is a cheap CI check for a fork
in exactly this position."). Merge artifact from the Codex pass. One-line delete.

## Key Decisions

- **Rebase/merge from upstream is off the table** — 291 upstream commits vs 82
  fork commits, and 11 of the 14 shared skills moved on *both* sides. Every port
  is manual. Only `receiving-code-review`, `dispatching-parallel-agents`, and
  `verification-before-completion` are untouched by this fork and can be taken
  wholesale.
- **Decline upstream's SDD single-reviewer consolidation (#1717)** — the PR
  author publicly corrected their own claim (two reviewers catch planted
  duplication 4/5 vs the new design's 3/5), and `@cchamplin` reported doubled
  token usage from restarts plus a "nag machine" controller. This fork keeps its
  two-reviewer flow.
- **Take the SDD hardening that does not depend on #1717** — RED/GREEN evidence
  fields (#1065), reviewer diff scoping (#1538), read-only reviewers (#1543),
  and a bounded fix loop (#1998). Verified separable.
- **Keep `verification-before-completion`'s "dishonesty" line** — upstream cut it
  under an eval they themselves flagged *inconclusive, low-confidence*.
- **Do not port upstream's `CHANGELOG.md` deletion (#1163)** — this fork actively
  maintains both `CHANGELOG.md` and `RELEASE-NOTES.md` per `.version-bump.json`.
- **Gemini needs no action** — this fork ships `gemini-extension.json`,
  `GEMINI.md`, and `skills/using-superpowers/references/gemini-tools.md`.
  Upstream removed Gemini (#1846) then reverted (#1959); the fork already
  matches where upstream landed.
- **Worktree rewrite (#1121/#1124) cannot be ported** — this fork's
  `using-git-worktrees` is Rails/SQLite-specific (246 lines vs upstream's 167)
  and delegates to `using-sqlite-worktrees`. Take only the transferable research
  finding: *agents anchor on code blocks and skip prose* (0/4 consent compliance
  when the gate was prose).
- **Batch 1 landed as five commits, not one** — the causes differ (harness
  manifest semantics, a shell bug, a keyword-scanner trap, broken links, personal
  references), so each is independently revertable with its own recorded WHY.
- **Rationale must come from merged PRs, not inference** — upstream enforces a PR
  template with "What problem are you trying to solve?" and "What alternatives
  did you consider?", so every claim is quotable first-hand.

## Modified Files

All committed on `lg/upstream-divergence-integration`; working tree clean.

- `docs/plans/2026-08-04-upstream-divergence-review.md` (new)
- `.codex-plugin/plugin.json`
- `skills/systematic-debugging/find-polluter.sh`
- `skills/systematic-debugging/SKILL.md`
- `skills/systematic-debugging/CREATION-LOG.md`
- `skills/systematic-debugging/root-cause-tracing.md`
- `skills/test-driven-development/SKILL.md`
- `skills/writing-skills/SKILL.md`
- `skills/receiving-code-review/SKILL.md`
- `skills/using-superpowers/SKILL.md`
- `skills/using-git-worktrees/SKILL.md`
- `docs/testing.md`

## Failed Approaches

- **`tests/opencode/run-tests.sh` is red on clean `main`** — `test-plugin-loading.sh`
  runs `cp .../lib` and this repo has no `lib/` directory. Confirmed pre-existing
  by stashing Batch 1 and re-running. Do not chase this while porting; it is a
  separate fix.
- **Ruby 2.6 is the active system Ruby** (`ruby -v` → 2.6.10). An endless method
  definition (`def blob(ref, path) = ...`) dies with a syntax error. Use classic
  `def`/`end` for throwaway scripts, or activate a modern Ruby via chruby first.
- **zsh mangles `$MB:path` in `git show`** — the `:` triggers modifier parsing and
  yields "bad substitution". Use `${MB}:path`.
- **`grep --include=*.md` unquoted in zsh** fails with "no matches found". Quote
  the glob or pass explicit directories.
- **Assuming Codex would write a separate plan file was wrong** — it edited
  `docs/plans/2026-08-04-upstream-divergence-review.md` in place, growing it from
  921 to 1172 lines. Check file size/heading diff before hunting for a second doc.

## Files to Read

- `docs/plans/2026-08-04-upstream-divergence-review.md` — **the primary artifact.**
  Tiered assessment, per-item upstream rationale with quotes, suggested order,
  verification boundary, and Appendix A (all 291 commits classified).
- `docs/handoffs/_archive/2026-04-21-sqlite-worktrees-skill.md` — context on why
  the worktree skill diverged from upstream (SQLite/Rails 8 multi-DB seeding).

## Next Steps

Batch 1 is done. Resume at Batch 2.

1. **Batch 2 — small, cited, low risk:**
   - `.opencode/plugins/superpowers.js` — `getBootstrapContent()` is called at
     line 84 on *every* `messages.transform`, doing a full `readFileSync` +
     frontmatter parse + template build **before** the already-injected
     early-return at line 89. Either hoist the injection check above the call or
     cache the string at module level. Preserve the fork's handoff/compaction
     hooks. (issue #1202)
   - `skills/brainstorming/scripts/server.cjs` — add a 10 MiB
     `MAX_FRAME_PAYLOAD_BYTES` rejected from the frame header alone, before the
     `Buffer.alloc(payloadLen)` at line 66 (length read from client at line 56).
     (#1555)
   - Port `dispatching-parallel-agents` and `receiving-code-review` wholesale via
     `git checkout upstream/main -- skills/<name>/SKILL.md`. Both were
     byte-identical to the merge base. **Note:** `receiving-code-review` now
     carries the Circle K fix from `7dea012`, and upstream's copy contains the
     same replacement, so the port should overwrite cleanly — verify that before
     committing rather than assuming it.

2. **Batch 3 — brainstorm companion hardening (#1720), land separately:**
   `skills/brainstorming/scripts/server.cjs` is the 338-line pre-hardening
   version (upstream's is 723). No authentication, any origin accepted; on a
   `--host 0.0.0.0` bind any routable host can read screens and inject fake
   `click` events into `state/events`, which the agent consumes as the user's
   next selection — prompt injection into a live session. Also: null-payload
   crash (#1504), `._*.html` resource-fork files served as mockups (#950),
   30-minute silent idle death (`server.cjs:247`, #1237). The `scripts/` dir has
   the same 5 files as upstream, so `git checkout upstream/main -- skills/brainstorming/scripts/`
   is close to viable, then re-apply this fork's `SKILL.md` wiring.
   **Bring upstream's `tests/brainstorm-server` (12 files) with it.**
   Batch 2's frame cap is a subset of this — if Batch 3 lands soon after, take
   the cap as part of the wholesale port instead of hand-patching twice.

3. **Batch 4 — manual ports requiring judgment:**
   - **Fix `skills/finishing-a-development-branch/SKILL.md`.** Confirmed live bug,
     worse here than upstream's version: line 143 runs
     `git worktree list | grep $(git branch --show-current)`, but Option 1
     (line 73) and Option 4 (line 131) already did `git checkout <base-branch>`,
     so it greps the *base* branch and matches the main worktree. Option 1's
     `git branch -d` at line 85 also runs while the worktree is still attached,
     which git refuses — Option 1 is broken end to end. Capture the worktree path
     in Step 2 before any `cd`; remove the worktree before deleting the branch;
     drop the hardcoded `gh pr create` (line 97); demote discard off the menu.
     (#1933)
   - Add the `writing-skills` form-selection section (+33 lines, additive,
     modifies no existing tuned content). Evidence: prohibitions *backfire* on
     composition-shaping problems — 4.4 restated values/dispatch vs 3.6 for the
     no-guidance control, while a positive recipe scored 3.0 with zero variance.
     (#1741)
   - SDD subset: RED/GREEN evidence fields in `implementer-prompt.md` (#1065),
     reviewer diff scoping (#1538), read-only reviewers (#1543), and a round cap
     at `skills/subagent-driven-development/SKILL.md:258` which currently reads
     `- Repeat until approved` with no limit (#1998).
   - Merge `agents/code-reviewer.md` (48 lines, generic persona) into
     `skills/requesting-code-review/code-reviewer.md` (153 lines, Ruby/Rails
     template with different placeholders) and delete `agents/`. Drift is
     confirmed real, and Codex cannot dispatch named agents. (#1299)
   - Delete `commands/{brainstorm,execute-plan,write-plan}.md` — three pure
     deprecation stubs, deprecated since 5.0.0, fork is at 7.4.0. (#1188)
   - Move sole-carrier requirements to their point of use **before** pruning
     Integration sections: the worktree prerequisite for `executing-plans` and
     SDD, and systematic-debugging's verification-before-completion handoff, are
     currently stated nowhere else. (#1932)

4. **Open the PR** against `lucianghinda/superpowers-ruby` once the intended
   batches are in. Decide whether Batches 2–4 join this branch or get their own.

5. **Optional, cheap:** add a CI check comparing every `[text](#anchor)` link
   against the headings present in its target file — the method that found
   upstream #2010 while someone was syncing a downstream fork.

6. **Separate from this effort:** fix the broken `tests/opencode` runner, and
   delete the duplicated sentence at line 712 of the review doc.

## Open Questions

- **Does this fork have Windows users?** Two gaps are real but only matter if so:
  `hooks/hooks.json` lacks `"shell": "bash"` on the SessionStart registration
  (without Git Bash, PowerShell parses the quoted-path command as a string
  expression and the bootstrap silently never loads — #1993), and
  `hooks/hooks-cursor.json` still calls `./hooks/session-start` directly rather
  than `./hooks/run-hook.cmd session-start`, which can surface the Windows
  "Open with" dialog (#1054).
- **Keep `~/.config/superpowers/worktrees`?** Still offered at
  `skills/using-git-worktrees/SKILL.md:71`. Upstream removed the user-global
  fallback (#1476) as confusing, but this fork may deliberately want a stable
  cross-project location. Policy call needed before touching the Rails/SQLite
  worktree skill.
- **Is `gh` a deliberate hard assumption?** Upstream made PR creation
  forge-agnostic (#1665/#1933). If this fork is GitHub-only forever, dropping the
  hardcoded `gh pr create` is portability polish rather than a fix — though the
  surrounding sequencing bug in that same skill must be fixed regardless.
- **Does a version bump belong with these ports?** Per project convention a bump
  touches 9 files (`scripts/bump-version.sh` handles 6 JSON manifests; CHANGELOG,
  RELEASE-NOTES, and the `#vX.Y.Z` pin in `.opencode/INSTALL.md` are manual). Not
  done for Batch 1.
