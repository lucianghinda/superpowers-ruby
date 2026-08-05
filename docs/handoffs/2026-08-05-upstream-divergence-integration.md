---
created: 2026-08-05T03:47:08Z
branch: main
trigger: manual
restored: false
topic: upstream-divergence-integration
---

# Handoff: upstream divergence review → integration batches

## Goal

Review everything that landed in `obra/superpowers` since this fork diverged
(merge base `8ea3981`, 2026-03-19, ≈ upstream v5.0.5), decide what is worth
porting into `superpowers-ruby` v7.4.0, and record the *why* for each proposal
sourced from the merged upstream PR discussion rather than guessed. The review
is complete and agreed; the porting work has not started.

## Current State

**Done:**
- Full triage of the 291-commit upstream delta / 100 merged PRs since divergence
- Review document written to `docs/plans/2026-08-04-upstream-divergence-review.md`
  (1172 lines, **untracked** — not committed yet)
- Two independent reviewers ran over this: Claude (PR-rationale depth) and Codex
  (commit-ledger completeness + harness manifests). Codex merged its findings
  into the same file rather than writing a separate doc.
- Every fork-state claim in the document was verified by grep against the working
  tree. No claim is carried on trust.
- Integration order agreed as four batches (see Next Steps).

**Not started:**
- No skill, script, hook, or manifest has been modified. The repo is clean apart
  from the untracked review document.

**Known doc defect:** line 712 of the review doc duplicates the sentence already
wrapped at lines 709–710 ("That is a cheap CI check for a fork in exactly this
position."). Merge artifact from the Codex pass. One-line delete.

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
  and a bounded fix loop (#1998). Codex's decomposition; verified separable.
- **Keep `verification-before-completion`'s "dishonesty" line** — upstream cut it
  under an eval they themselves flagged *inconclusive, low-confidence*. Not
  enough evidence to follow.
- **Do not port upstream's `CHANGELOG.md` deletion (#1163)** — this fork actively
  maintains both `CHANGELOG.md` and `RELEASE-NOTES.md` per `.version-bump.json`.
  Upstream's simplification would delete live fork history.
- **Gemini needs no action** — this fork ships `gemini-extension.json`,
  `GEMINI.md`, and `skills/using-superpowers/references/gemini-tools.md`.
  Upstream removed Gemini (#1846) then reverted (#1959); the fork's current state
  already matches where upstream landed.
- **Worktree rewrite (#1121/#1124) cannot be ported** — this fork's
  `using-git-worktrees` is Rails/SQLite-specific (246 lines vs upstream's 167)
  and delegates to `using-sqlite-worktrees`. Take only the transferable research
  finding: *agents anchor on code blocks and skip prose* (0/4 consent compliance
  when the gate was prose).
- **Rationale must come from merged PRs, not inference** — upstream enforces a PR
  template with "What problem are you trying to solve?" and "What alternatives
  did you consider?", so every claim in the review doc is quotable first-hand.

## Modified Files

- `docs/plans/2026-08-04-upstream-divergence-review.md` — **untracked**, needs a
  commit decision

Nothing else in the tree is touched.

## Failed Approaches

- **Ruby 2.6 is the active system Ruby** (`ruby -v` → 2.6.10). The first helper
  script used an endless method definition (`def blob(ref, path) = ...`) and died
  with a syntax error. Use classic `def`/`end` for throwaway scripts here, or
  activate a modern Ruby via chruby first.
- **zsh mangles `$MB:path` in `git show`** — the `:` triggers modifier parsing and
  yields "bad substitution". Use `${MB}:path`.
- **`grep --include=*.md` unquoted in zsh** fails with "no matches found". Quote
  the glob or pass explicit directories.
- **Assuming Codex would write a separate plan file was wrong** — it edited
  `docs/plans/2026-08-04-upstream-divergence-review.md` in place, growing it from
  921 to 1172 lines. Check file size/heading diff before looking for a second doc.

## Files to Read

- `docs/plans/2026-08-04-upstream-divergence-review.md` — **the primary artifact.**
  Contains the tiered assessment, per-item upstream rationale with quotes, the
  suggested order, the verification boundary, and Appendix A (all 291 commits
  classified). Read this first; everything below is a summary of it.
- `docs/handoffs/_archive/2026-04-21-sqlite-worktrees-skill.md` — context on why
  the worktree skill diverged from upstream (SQLite/Rails 8 multi-DB seeding).

## Next Steps

Batches are ordered by risk. Batch 1 is mechanical and was explicitly offered to
the user as the starting point.

1. **Batch 1 — five defect fixes, one commit (~30 lines, zero risk):**
   - `.codex-plugin/plugin.json` — add top-level `"hooks": {}`. Currently absent,
     so Codex auto-discovers the root `hooks/hooks.json` (Claude's SessionStart
     registration) and tries to run a Claude-shaped hook. (upstream #1897)
   - `skills/systematic-debugging/SKILL.md:240` — `Ultrathink` → `Ultra-think`.
     Trips Claude Code's keyword scanner and silently forces extended thinking on
     every session that loads the skill. (#1558)
   - `skills/test-driven-development/SKILL.md:349` and
     `skills/writing-skills/SKILL.md:570` — replace `@file.md` with relative
     markdown links. (#1532, #631)
   - `skills/systematic-debugging/find-polluter.sh:22` — `find . -path "./$TEST_PATTERN"`
     plus an empty-result guard so `TOTAL` is 0 rather than `wc -l`'s 1. Currently
     a silent no-op that reports "Found 1 test files" and exits clean. (#2011)
   - Cosmetics: `skills/receiving-code-review/SKILL.md:129` (Circle K phrase →
     upstream's plain-language replacement, #1531);
     `skills/using-superpowers/SKILL.md:101,105,109` (bare `debugging` →
     `systematic-debugging`, #1601); `/Users/jesse` in
     `skills/using-git-worktrees/SKILL.md:216`,
     `skills/systematic-debugging/CREATION-LOG.md:7`,
     `skills/systematic-debugging/root-cause-tracing.md:36`,
     `docs/testing.md:152` (#1122).

2. **Batch 2 — small, cited, low risk:**
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
     `git checkout upstream/main -- skills/<name>/SKILL.md`. Both are
     byte-identical to the merge base here.

3. **Batch 3 — brainstorm companion hardening (#1720), land separately:**
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

4. **Batch 4 — manual ports requiring judgment:**
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

5. **Decide whether to commit the review document** and this handoff, and on
   which branch. Currently on `main` with the review doc untracked. Per project
   convention PRs target `lucianghinda/superpowers-ruby`; branch before
   committing rather than committing to `main`.

6. **Optional, cheap:** add a CI check that compares every `[text](#anchor)` link
   against the headings actually present in its target file — the method that
   found upstream #2010 while someone was syncing a downstream fork.

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
- **Commit the untracked review doc, or keep it local?** It is a large analysis
  artifact, not shipped plugin content.
