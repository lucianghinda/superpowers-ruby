# Upstream Divergence Review — `obra/superpowers` → `lucianghinda/superpowers-ruby`

**Date:** 2026-08-04
**Status:** Assessment — no code changed yet
**Method:** upstream git history + merged-PR bodies/comments on `obra/superpowers`,
cross-checked against this fork's current files

---

## Scope

| | |
|---|---|
| Divergence point (merge base) | `8ea39819eed74fe2a0338e71789f06b30e953041` — 2026-03-19, *"Add issue templates and disable blank issues"* (≈ upstream v5.0.5) |
| Upstream commits since divergence | **291** |
| Upstream merged PRs in calendar window | **99** |
| Fork commits since divergence | **82** |
| Upstream version travel | ~v5.0.5 → **v6.2.0** |
| Fork version | **v7.4.0** (independent line) |
| Upstream tip reviewed | `44c9b2d6e889982ac18c27d05a19fefe335194e1` — 2026-07-28 |

Fork and upstream share **14 skills**. Everything else in this fork
(`ruby`, `rails-guides`, `rails-upgrade`, `sandi-metz-rules`, `brakeman`,
`37signals-style`, `hwc-*`, `handoff*`, `compound*`, `consulting-an-oracle`,
`using-sqlite-worktrees`, `ruby-commit-message`, `ruby-upgrade`) has no upstream
counterpart and is out of scope.

A rebase is not viable. Every proposal below is a manual port or a
reimplementation.

The 99-PR figure is a calendar-window search, not a claim that every one of
those PRs contributed a commit to the current `main`: superseded and reverted
work can still appear in GitHub's merged search. The authoritative code scope
is the 291-commit ancestry range. Appendix A accounts for every commit in that
range.

Patch-equivalence analysis (`git cherry main upstream/main`) found:

| Status | Count | Meaning |
|---|---:|---|
| Upstream-only patches | 285 | No patch-equivalent change exists in this fork |
| Already patch-equivalent | 3 | Upstream `2b1bfe5`, `e6221a4`, and `3f80f1c` already exist here under different SHAs |
| Merge commits | 3 | `b7a8f76`, `a569527`, and `f9b088f`; `git cherry` does not classify merges |

This matters because raw ancestry says 291, but the actionable patch delta is
smaller: do not manually re-port the three equivalent changes, and judge the
three merge commits through their constituent commits.

---

## Reproducing this analysis

```bash
git fetch upstream
git merge-base main upstream/main                      # -> 8ea3981
git rev-list --left-right --count main...upstream/main # -> 82  291
git log --oneline --reverse main..upstream/main        # the 291 commits

gh pr list --repo obra/superpowers --state merged --limit 200 \
  --json number,title,mergedAt,author,url \
  --jq '.[] | select(.mergedAt >= "2026-03-19") | [.number,.mergedAt[0:10],.author.login,.title] | @tsv'
```

For PR-backed changes, every "why" below comes from the merged PR body or its
comment thread on `obra/superpowers`. Upstream enforces a PR template with
*"What problem are you trying to solve?"* and *"What alternatives did you
consider?"*, so rationale is first-hand, not inferred. Some release batches
were committed directly to `main` and have no merged PR thread; those are
identified as such and use the upstream commit body, design/spec, linked issue,
or release notes. Where GitHub no longer exposes a referenced PR, the report
says so instead of reconstructing a motive.

---

## Disposition of the complete 291-commit delta

Appendix A is the exact commit-by-commit accounting. The table below groups
that ledger into the integration decisions that avoid treating release bumps,
tests, specs, and follow-up commits as unrelated proposals.

| Initiative family | What the upstream commits were trying to achieve | Fork decision |
|---|---|---|
| Codex App dispatch and bootstrap | Make native Codex installs understand agent dispatch and avoid Claude-hook auto-discovery | Named dispatch is already patch-equivalent. **Take** the explicit empty-hooks manifest fix; retain this fork's Ruby bootstrap. |
| Copilot and OpenCode runtime | Correct Copilot's `additionalContext` shape, align OpenCode paths/channel, avoid per-turn bootstrap I/O | Copilot payload support is already present. **Take** the OpenCode cache; preserve fork-specific handoff hooks. |
| Brainstorm companion security/lifecycle | Separate served content from state, authenticate every endpoint, cap frames, fix PID/timeout/reconnect/Windows behavior | **Take**, with upstream regression tests. This is the highest-value runtime family. |
| Worktree behavior | Restore user consent, prefer native isolation tools, remove the confusing global fallback, cover multi-repo plans | **Manually adapt.** The Ruby fork's Rails/SQLite flow is incompatible with a wholesale port, but the consent evidence and hardcoded-path cleanup apply. |
| SDD cost and auditability | Reduce review cost, scope reviewers, persist evidence, bound repair loops, isolate plan state | **Mixed.** Decline single-reviewer consolidation; take evidence, read-only/scoping, and bounded fix-loop pieces; defer durable workspace until needed. |
| Skill authoring/testing redesign | Teach form-selection, positively frame good tests, repair references, and remove token-cost detritus | **Selective take.** Port evidence-backed additive guidance; compress only after preserving Ruby-specific and eval-proven load-bearing text. |
| Branch finishing and legacy commands | Stop advertising destruction, fix worktree cleanup, become forge-neutral, remove expired stubs | **Take manually.** Exact bugs and stale commands exist here. |
| Shared-skill compression | Remove social proof, recaps, redundant Integration indexes, and harness-specific pseudo-code | **Selective take.** Three clean ports are low risk; move sole-carrier requirements before deleting indexes. |
| Codex mirror/portal packaging | Automate upstream's separate marketplace mirror and create portal archives | **Skip infrastructure.** This fork publishes its own plugin line; only portable manifest correctness applies. |
| Gemini/Kimi/Antigravity/pi/new harnesses | Add or remove harness-specific manifests, mappings, docs, and tests | **Skip unsupported harnesses.** Keep Gemini because this fork currently declares support; upstream itself reverted its removal. |
| Evals submodule and experiment artifacts | Move behavioral drills into a canonical harness and record SDD/compression experiments | **Skip the submodule.** Upstream later stopped shipping it because it broke plugin installs; retain the findings cited in this assessment. |
| Releases, versions, community, hiring, governance | Cut v5.1–v6.2, maintain upstream metadata/docs, and raise contribution-quality gates | **Do not port mechanically.** The fork has an independent v7.x history and contributor surface; adopt only still-correct links or governance ideas. |
| Specs, plans, tests, reverts, and merge commits | Design and verify the initiatives above, or undo superseded attempts | Bring tests with accepted runtime changes; use specs as implementation references; do not port superseded/reverted patches or merge commits separately. |

This grouping is exhaustive at the initiative level: every Appendix A subject
falls into one of these rows, and every proposed port is expanded below with
the upstream rationale and fork-specific evidence.

---

## Integration difficulty map (shared skills)

Three-way comparison of `SKILL.md` at merge-base vs `main` vs `upstream/main`:

| Skill | Fork changed? | Upstream changed? | Port difficulty |
|---|---|---|---|
| `receiving-code-review` | no | 213→205 | **clean port** |
| `dispatching-parallel-agents` | no | 182→167 | **clean port** |
| `verification-before-completion` | no | 139→120 | **clean port** |
| `subagent-driven-development` | 277→277 | 277→503 | both moved |
| `brainstorming` | 164→195 | 164→151 | both moved |
| `using-superpowers` | 115→187 | 115→62 | both moved |
| `writing-skills` | 655→670 | 655→679 | both moved |
| `test-driven-development` | 371→363 | 371→320 | both moved |
| `finishing-a-development-branch` | 200→201 | 200→201 | both moved |
| `writing-plans` | 145→152 | 145→168 | both moved |
| `systematic-debugging` | 296→296 | 296→283 | both moved |
| `requesting-code-review` | 105→105 | 105→95 | both moved |
| `executing-plans` | 70→70 | 70→64 | both moved |
| `using-git-worktrees` | 218→246 | 218→167 | both moved (diverged most) |

---

## Tier 1 — Take now: verified defects live in this fork

Each item below was grepped against this repo's working tree. File and line
numbers are from this fork, not upstream.

### 1.0 Codex manifest omits the explicit empty hooks field

**Location:** `.codex-plugin/plugin.json` has no top-level `hooks` field, while
this repository also contains `hooks/hooks.json` for Claude Code.

**Upstream fix:** [PR #1897](https://github.com/obra/superpowers/pull/1897)
(`obra`, merged 2026-07-01, released as v6.1.1).

This was merged as a critical Codex compatibility fix. Codex distinguishes
between a manifest whose `hooks` field is absent and one whose `hooks` field is
an explicit empty object. When the field is absent, Codex auto-discovers the
repository-root `hooks/hooks.json`; that file contains Claude's SessionStart
registration, so Codex tries to register and run a Claude-shaped hook it should
ignore. The PR author summarized the required shape as:

> "only `hooks: {}` suppresses auto-discovery."

The PR considered an empty array and deleting the hook files. The empty array
did not express the schema Codex expects, while deleting the files would break
Claude Code support. The empty object is therefore both the smallest and the
only cross-harness-safe fix.

**Change:** add top-level `"hooks": {}` to `.codex-plugin/plugin.json`. Keep
`hooks/hooks.json` unchanged for Claude Code. This is a one-line semantic fix,
not metadata cosmetics, and should be the first port.

### 1.1 WebSocket unbounded allocation

**Location:** `skills/brainstorming/scripts/server.cjs:66` — `Buffer.alloc(payloadLen)`
where `payloadLen` comes from a client-supplied 64-bit frame header (line 56,
`buffer.readBigUInt64BE(2)`). No cap anywhere in the file.

**Upstream fix:** PR #1555 (`therahul-yo`, merged 2026-06-02, fixes #1446).
The PR demonstrates that a local client can advertise an enormous 64-bit frame
length and drive `Buffer.alloc(payloadLen)` directly. It rejected waiting until
the whole frame arrived because the dangerous declared size would remain in
control flow, and rejected adding a WebSocket package to keep the project
dependency-light.

**Change:** 10 MiB `MAX_FRAME_PAYLOAD_BYTES`, rejected from the header alone
before allocation, exported for tests. ~15 lines.

**Verify:** `grep -n 'MAX_FRAME\|Buffer.alloc(payloadLen)' skills/brainstorming/scripts/server.cjs`

---

### 1.2 Brainstorm companion server has no authentication

**Location:** `skills/brainstorming/scripts/server.cjs` — 338 lines.
Upstream's hardened version is 723 lines.
`grep -n 'sessionKey\|SESSION_KEY\|Origin\|403' server.cjs` returns **nothing**.

**Upstream fix:** PR #1720 (`obra`, merged 2026-06-11). The PR and linked issues
document an unauthenticated HTTP/WebSocket server that accepted any origin. A
malicious tab—or any routable host when bound to `0.0.0.0`—could read screens
and inject fake click events that the agent would consume as the user's next
selection. That is a prompt-injection path into a live session, not merely a
localhost hardening preference (issues #1014, #1553, #1110).

The same PR bundled four independently reported failures: a four-byte `null`
payload crashed the process (#1504); macOS/ExFAT/SMB `._*.html` resource-fork
files could be served as the newest mockup (#950); the 30-minute idle timeout
expired silently during real sessions (#1237); and the client had a misleading
fixed-delay reconnect state with no useful status feedback.

This fork confirms the 30-minute timeout at `server.cjs:247`
(`const IDLE_TIMEOUT_MS = 30 * 60 * 1000;`).

**Change upstream shipped:** per-session secret-key auth on every endpoint
(+ cookie bootstrap, friendly 403, null-payload guard); resource-fork dotfile
filtering; ownership-checked `stop-server.sh`; 4h configurable idle timeout that
closes WebSockets cleanly; exponential-backoff reconnect with live status and a
"paused" overlay; same-port + same-key restart; opt-in `--open` browser launch
with an argv-safe Windows/WSL launcher; and offering the companion just-in-time
rather than upfront.

**Effort:** large (22 files, +4910/-90 upstream). But this fork's `scripts/`
directory has the same 5 files as upstream and is at the pre-hardening baseline,
so `git checkout upstream/main -- skills/brainstorming/scripts/` is close to
viable — then re-apply this fork's `SKILL.md` wiring and Ruby-specific prose.

**This is the highest-value item in the review.** The server ships in this
plugin, is unauthenticated, and the prompt-injection path into a live agent
session is real.

---

### 1.3 `find-polluter.sh` is a silent no-op

**Location:** `skills/systematic-debugging/find-polluter.sh:22`
`TEST_FILES=$(find . -path "$TEST_PATTERN" | sort)`

**Upstream fix:** PR #2011 (`arimu1`, merged 2026-07-23, fixes #2008). The PR
explains that `find .` prefixes results with `./`, so an unprefixed `-path`
pattern matches nothing. `wc -l` on the empty shell string then reports one,
making a zero-test run look successful. Before merging, the maintainer
reproduced that silent no-op in a toy repository, verified that the fix found
and bisected the polluter, confirmed honest zero-result reporting, and ran
shellcheck.

**Change:** `find . -path "./$TEST_PATTERN"` plus an empty-result guard so
`TOTAL` is 0 rather than `wc -l`'s 1 on empty stdin.

**Known residual:** the maintainer noted that an already-`./`-prefixed input
would be double-prefixed, while `src/**/*.test.ts` would miss tests directly
under `src/`. Upstream handled both in follow-up commit `c8921b5`; the manual
port should take that follow-up too.

---

### 1.4 `Ultrathink` triggers the Claude Code keyword scanner

**Location:** `skills/systematic-debugging/SKILL.md:240`
`- "Ultrathink this" - Question fundamentals, not just symptoms`

**Upstream fix:** PR #1558 (`ngalatis`, merged 2026-05-23, fixes #1283). The PR
shows that Claude Code scans tool-result text for the contiguous trigger token.
Loading this skill therefore injected an extended-thinking reminder even when
the user never requested it, changing token cost and model behavior.

Reproduced independently by two people across two versions (superpowers 5.0.7 /
CC 2.1.119, and CC 2.1.143 / Opus 4.7), each with two clean subagent contexts.

**Change:** one character. `Ultrathink` → `Ultra-think`.

The maintainer accepted `Ultra-think` because it preserves the intended
meaning while breaking the exact contiguous sequence the runtime scans.

---

### 1.5 Unresolvable `@`-style file references (2 sites)

**Locations:**
- `skills/test-driven-development/SKILL.md:349` — `read @testing-anti-patterns.md`
- `skills/writing-skills/SKILL.md:570` — `See @testing-skills-with-subagents.md`

**Upstream fixes:** PR #1532 (`arittr`, fixes #1529) and PR #631
(`stablegenius49`). The PRs explain that `@...md` is not a resolvable Markdown
link, so agents either treat it as literal text or guess a path. Issue #1529
reported that exact confusion even though the intended file existed.

**Change:** relative markdown links. 2 lines.

---

## Tier 2 — Take: correctness and portability, low risk

### 2.0 Cache OpenCode bootstrap content once per plugin process

**Fork state:** `.opencode/plugins/superpowers.js` reads the bootstrap skill
with `fs.readFileSync` inside `experimental.chat.messages.transform`. There is
no module-level bootstrap cache, so every transformed turn repeats the file
read and parse.

**Upstream trail:** [issue #1202](https://github.com/obra/superpowers/issues/1202)
and its maintainer resolution, followed by the v5.1.0 release commit. The
reported problem was not theoretical startup cost: `messages.transform` runs
on every agent step, so unchanged plugin content was repeatedly read from disk.
The maintainer's resolution records the fix as caching the module content once
instead.

GitHub no longer resolves the referenced `#1232` page as a public PR/issue, so
this review does **not** invent a missing PR rationale. The evidence used here
is the original issue discussion plus the merged commit and release notes.

**Change:** cache the bootstrap string at module initialization and reuse it in
the transform hook. Preserve this fork's handoff/compaction integration; only
the repeated bootstrap read should move. Small change, low behavior risk.

### 2.1 Hardcoded `gh pr create`

**Location:** `skills/finishing-a-development-branch/SKILL.md:97`

**Upstream fix:** PR #1665 (`arimu1`, issue #1609), superseded by #1933. The
original problem was that GitLab, Gitea, and self-hosted repositories either
lack `gh` or could create the wrong review. The maintainer rejected a growing
platform-detection table and preferred deleting the CLI-specific block.
#1933 kept that principle: naming `gh` and `glab` would bless only two forges
and eventually rot, while the review URL printed after a push is portable.

**Fork-specific judgment:** this fork's workflow is GitHub-only. Take this for
portability of the published plugin; skip if `gh` is a deliberate hard
assumption. Not a defect for the maintainer personally.

---

### 2.2 "Circle K" personal shibboleth

**Location:** `skills/receiving-code-review/SKILL.md:129`
`**Signal if uncomfortable pushing back out loud:** "Strange things are afoot at the Circle K"`

**Upstream fix:** PR #1531 (`arittr`, SUP-246, reported by `@dantowne`). The PR
records that the phrase was a personal instruction accidentally shipped in
core. Deleting the whole line was rejected because the underlying behavior—an
agent naming its discomfort before raising a real concern—was still useful.
Upstream replaced the private shibboleth with direct, generic guidance to name
the tension and explain the issue.

---

### 2.3 Bare `debugging` in the bootstrap

**Locations:** `skills/using-superpowers/SKILL.md` lines 101, 105, 109.

Line 129 of the same file correctly names `superpowers-ruby:systematic-debugging`,
so the file is internally inconsistent.

**Upstream fix:** commit `b0a0872` / PR #1601 (`obra`). The commit records a
user report that Claude interpreted bare `debugging` as a skill name even
though the actual skill is `systematic-debugging`.

Diff was three swaps of `debugging` → `systematic-debugging` in:
process-skills-first list, the "Fix this bug →" example, and the Rigid skills list.

---

### 2.4 Hardcoded `/Users/jesse`

**Locations in this fork:**
- `skills/using-git-worktrees/SKILL.md:216`
- `skills/systematic-debugging/CREATION-LOG.md:7`
- `skills/systematic-debugging/root-cause-tracing.md:36`
- `docs/testing.md:152`

**Upstream fix:** PR #1122 (`arittr`, #858). The PR treats these as both a
portability defect and a leak of a contributor's private directory layout.

Upstream replaced with `~/project` / `<project-root>`.

---

### 2.5 Clean-port compression of three untouched skills

`verification-before-completion`, `dispatching-parallel-agents`, and
`receiving-code-review` are byte-identical to the merge base in this fork.
Upstream cut −19, −24, and −10 lines.

**Upstream change:** PR #1934 (`obra`, merged 2026-07-14, eval-gated). It targets
content that costs context on every load without changing behavior: social
proof, self-selling sections, and recaps that repeat rules already located at
the decision point. Fourteen agents audited the skills, but the author then
hand-checked every claimed duplicate after discovering one automated estimate
was inflated by 2.6×.

The evaluation is also the reason not to port blindly: 11 of 12 proposed cuts
behaved as detritus, but deleting TDD's order rationale measurably weakened
test-first behavior under pressure, so upstream folded that reasoning into the
active rule instead. The `verification-before-completion` result was explicitly
inconclusive and low-confidence.

**Recommendation:**
- `dispatching-parallel-agents` — take. Beyond the cuts, it replaces a fake
  TypeScript `Task(...)` block with harness-neutral prose and adds the
  load-bearing sentence: *"Multiple dispatch calls in one response = parallel
  execution. One per response = sequential."*
- `receiving-code-review` — take. Includes 2.2 above and
  `CLAUDE.md` → `instruction-file` neutralization.
- `verification-before-completion` — **partially decline.** The deleted line
  *"Claiming work is complete without verification is dishonesty, not
  efficiency"* was cut on an explicitly inconclusive, low-confidence eval.
  Recommend keeping it.

---

## Tier 3 — Judgment calls: design shifts, not fixes

### 3.1 SDD reviewer consolidation — recommend **declining the core change**

This fork ships the original two-reviewer design:
`spec-reviewer-prompt.md` + `code-quality-reviewer-prompt.md`.
Upstream now ships `task-reviewer-prompt.md` + `re-review-prompt.md` + `scripts/`.

**Upstream rationale:** PR #1717 (`obra`, merged 2026-06-15). In the measured
session, seven of eight quality reviewers performed repository-wide searches;
the most expensive issued more than 50 shell commands over roughly 200 seconds,
and quality review cost four to eight times spec review for the same task. The
PR attributes this to reusing a branch-scale merge-readiness prompt for tiny
task diffs, giving controllers no prompt-bounding guidance, and making both
reviewers rediscover the same evidence.

Measured: sdd-svelte-todo 79.7 min / $20.98 → 55.0 min / $14.99 (−29%).

**Two counter-signals in the same PR thread.**

The author later corrected an overclaim in the same thread. On the planted DRY
defect, the old two-reviewer flow caught it on the first pass in 4/5 runs; the
new flow caught it in 2/5, or 3/5 after a constraints fix. A post-merge user
also reported that lower first-pass quality caused restarts, roughly doubled
their token use, and made the directing agent interrupt too often. These are
field reports, not a controlled reproduction here, but they directly oppose a
simple “same quality, lower cost” conclusion.

**Recommendation:** keep the two-reviewer design. This fork gets the better
first-pass catch rate and avoids the reported regression. The cost savings
matter most to someone running SDD at upstream's volume.

---

### 3.2 SDD fix-loop redesign — recommend **taking, separately from 3.1**

**Upstream rationale:** PR #1998 (`obra`, merged 2026-07-19). The old process
said to repeat full review until approval, with no breaker, so nondeterministic
reviewers could keep discovering new findings. It also contradicted itself over
whether the original implementer or a fresh fix agent owned corrections; live
baseline runs split between the two behaviors.

Shape adopted: rounds 1–3 resume the original implementer with findings;
rounds 4–5 dispatch a fresh implementer on a more capable model; a five-round
breaker triggers controller adjudication.

The PR rejected adding only a hard cap to full re-reviews because new findings
would remain nondeterministic; scoped re-review was intended to make each round
converge. The maintainer also rejected a mandatory human checkpoint at the
breaker because SDD is meant to execute autonomously.

**Action for this fork:** audit `skills/subagent-driven-development/SKILL.md`
for the same three-way contradiction (it predates the fix and likely inherited
it), and add a bounded fix loop. This is separable from 3.1 — it does not
require consolidating the reviewers.

### 3.2a SDD hardening that is safe to take without reviewer consolidation

Three upstream fixes address auditability and runaway reviewer scope without
requiring the contested single-reviewer design:

1. **Require RED/GREEN evidence in implementer reports.** The discussion on
   [issue #994](https://github.com/obra/superpowers/issues/994) and merged
   [PR #1065](https://github.com/obra/superpowers/pull/1065) identified that an
   implementer could claim TDD while giving the controller no proof that the
   test failed before the fix. Upstream added the failing-test command/output
   and passing-test command/output to the report contract. This fork's
   `implementer-prompt.md` has no equivalent evidence fields. **Take.**

2. **Give spec reviewers the task diff/file scope.** In
   [issue #1538](https://github.com/obra/superpowers/issues/1538), the report was
   that reviewers re-read the repository because the controller supplied no
   bounded evidence. Upstream accepted prompt-level diff scoping; it did not
   adopt the separate suggestion to solve the problem merely by routing to a
   cheaper model. **Take the scope, not the model-policy assumption.**

3. **Make reviewers explicitly read-only.** The detached-HEAD failures in
   [issue #1543](https://github.com/obra/superpowers/issues/1543) came from
   reviewers attempting implementation-side repository operations. Upstream
   added read-only guidance to the reviewer prompt. **Take**, while treating a
   controller-enforced sandbox/check as optional until reproduced here.

These are small manual prompt edits with direct failure reports behind them.
They improve the existing two-reviewer flow rather than forcing the fork to
accept #1717's quality tradeoff.

---

### 3.3 SDD durable workspace — **not applicable, but note the shape**

This fork has no `.git/sdd` and no `.superpowers/sdd`
(`grep -rn 'git-path sdd\|\.superpowers/sdd\|sdd-workspace' skills/ scripts/`
returns nothing). It never adopted upstream v6.0.3's workspace, so #1789's bug
does not bite.

For the record, in case durable SDD progress is added later, PR #1789 shows
that Claude Code denies agent writes to `.git/` as a protected path. The
implementer's report write failed, leaving the reviewer nothing to read. The
issue reproduced in ordinary `acceptEdits`, not only sandbox mode; shell helper
scripts had appeared to work because static command analysis could not resolve
their output variable to a literal `.git/` destination.

Final shape (PR #1943): `.superpowers/sdd/<plan-basename>/` with a self-ignoring
`.gitignore` containing `*`. Skip the `.git/sdd` intermediate entirely.

#1943 explicitly narrows its claim: all 25 fresh Sonnet controllers checked a
stale ledger against Git history and rejected it, although they spent 6–13
forensic tool calls doing so. The plan-scoped workspace removes that collision
and cost surface; it does not claim an observed error-rate improvement.

One post-merge objection on
[PR #2028](https://github.com/obra/superpowers/pull/2028) should constrain any
future port: `@Orvid` noted that deleting implementer reports at plan completion
breaks workflows that execute a series of related plans and expect later plans
to consult earlier evidence. If this fork adopts a durable workspace, cleanup
must be an explicit retention policy, not an unconditional end-of-plan delete.

---

### 3.4 Worktree default inversion — **cannot port; extract the insight**

Upstream inverted the default: work in place, worktree creation is an explicit
off-ramp.

**Upstream rationale:** PR #1124 (`arittr`, PRI-974). In the reported drill,
Claude Code and Codex followed the consent gate in 0/4 runs because it was
buried in conditional prose. The working hypothesis, supported by later runs,
was that agents anchor on code blocks more reliably than surrounding prose.

PR #1121 adds detect-and-defer behavior after observing agents call
`git worktree add` even when the harness offered managed isolation such as
`EnterWorktree`. Abstract wording succeeded in only 2/6 runs; explicitly naming
the native tool and bridging to user consent succeeded in 50/50 runs after
three refinement iterations.

PR #1476 removes the user-global path because the “global legacy” language
still suggested that new manual worktrees could be routed there, contradicting
upstream's desired behavior.

**Fork state:** `skills/using-git-worktrees/SKILL.md` is 246 lines vs upstream's
167, is Rails-specific (SQLite worktree seeding, `database.yml` handling,
delegation to `using-sqlite-worktrees`), and **still documents
`~/.config/superpowers/worktrees`** at line 71. Its heading structure
(`### 1. Check Existing Directories` … `### 3. Ask User`) bears no relation to
upstream's numbered steps, so #1522's renumbering fix is moot here.

**Extractable actions:**
1. The finding *"agents anchor on code blocks and skip prose"* is the
   transferable result. If this fork's consent gate is prose, move it into a
   code block.
2. Decide deliberately whether `~/.config/superpowers/worktrees` stays. Upstream
   removed it as confusing; this fork may have a reason to keep it.
3. Consider #1123's one-row addition to the Edge Cases table:
   > "Agents encountering multi-repo plans either created a worktree in only the
   > first repo or skipped worktree creation entirely for secondary repos,
   > leading to inconsistent isolation."

---

### 3.5 Named `code-reviewer` agent → inline template

**Fork state:** both `agents/code-reviewer.md` **and**
`skills/requesting-code-review/code-reviewer.md` exist. Upstream deleted the
`agents/` directory entirely.

**Upstream rationale:** PR #1299 (`obra`, merged 2026-04-30). The agent persona
and skill-local template were two independently drifting definitions; PR #915's
placeholder mismatch was a concrete symptom. Codex could not dispatch the
named agent directly and needed a fork-specific flattening workaround, while
Claude users were confusing the agent type with a skill (#1078).

Rejected: promoting the other reviewers to named agents
(*"more cross-platform compatibility headaches"*); leaving a stub for
backward-compat (*"named-agent registries are local to each user's harness
install — there's no public API to break here"*).

**Relevance:** this fork ships `.codex-plugin` and `.opencode`, so the Codex
dispatch limitation applies directly. **First action: diff the two files and
check whether they have already drifted.**

---

### 3.6 Bootstrap compression — adapt the technique, not the diff

**Fork state:** `skills/using-superpowers/SKILL.md` is 187 lines and contains
this fork's Ruby skills table — the point of the fork. Upstream went 115 → 62.

**Upstream rationale:** PR #1848 (`obra`, merged 2026-06-25). The bootstrap is
injected into every session, so its token cost is recurring. Upstream removed a
large graphviz flow, a standalone priority section, per-platform access
walkthroughs, and pointer lists that duplicated guidance elsewhere. It
deliberately kept the rationalization table, process-before-implementation
priority, and user-instruction precedence. A more aggressive variant still
passed clean triggering evals, but the maintainer chose the conservative cut to
retain more behavior-shaping content.

**Recommended adaptation:** drop the graphviz diagram in favour of the prose it
encodes; fold Instruction Priority into User Instructions; drop the per-platform
"How to Access Skills" walkthrough. Keep the Ruby skills table and the Red Flags
table.

Companion PR #1847 removed large action-to-tool tables and loading explainers
that modern harnesses already follow without prompting. After removing that
boilerplate, the Claude and Copilot references had no unique content left.

---

### 3.7 `writing-skills`: match guidance form to failure type — **highest leverage**

**Upstream change:** PR #1741 (`obra`, merged 2026-06-11), a purely additive
33-line change that leaves the existing Iron Law, Red Flags, rationalization
tables, and partner language intact.

**Why:** for a composition-shaping problem, a prohibition averaged 4.4 repeated
values per dispatch versus 3.6 with no guidance (n=5), while a positive recipe
averaged 3.0 with zero variance. Adding one nuance clause worsened the recipe to
3.8, and an exemption clause in another test still reduced test code by 62%.
The upstream skill taught prohibition plus loophole-closing as the universal
hardening form, so it actively steered authors toward the approach that
backfired on shaping tasks.

In the 35-sample baseline, authors produced prohibition-led guidance in all
five dispatch-restating runs and chose expensive full-subagent verification in
all five wording-change runs. The PR also reports the existing skill's wins:
all five plan-bloat runs rejected a word budget, and the Iron Law/baseline-first
guidance held in the placeholder and rerun tasks. Three of seven predicted
failures were falsified, which is why the change is additive rather than a
rewrite.

**Recommendation: take.** Additive, evidence-backed, and it compounds — it
changes how every future skill in this fork gets authored.

---

### 3.8 `testing-anti-patterns.md` → `writing-good-tests.md`

**Upstream change:** PR #1935 (`obra`, merged 2026-07-13). The old disclosure
document led with violations and three prohibitions. The PR follows upstream's
positive-instruction direction: lead with the behavior to perform so the wrong
pattern is not the most salient example.

Rejected: *"Rename only, keep violation-first structure: rejected — the title
was the symptom, the framing was the problem."*
Also rejected: merging into SKILL.md, because *"progressive disclosure is
correct here."*

The final version reduced eight accumulated rules to two principles: each test
names the failure it would catch, and each test exercises the real behavior.
Rules become corollaries, with one gate per principle and four example pairs;
the document fell from 2,094 to 1,310 words (37%). Evaluation subjects derived
conclusions that the flat version had stated explicitly, including rejecting a
ceremonial test of a typo-only change.

**Fork relevance:** pairs with fixing the broken `@`-link in 1.5. This fork's
TDD skill is Ruby-customized (363 vs upstream 320 lines), so this is a
rewrite-with-reference, not a port.

---

### 3.9 `finishing-a-development-branch` modernization — contains a live bug

**Upstream change:** PR #1933 (`obra`, merged 2026-07-13). Supersedes #1665.

Four problems drove the change: the normal completion menu advertised
destruction beside merging; cleanup recomputed the worktree path after changing
directories, making its provenance check and cleanup silently fail; “Push and
Create PR” did not create a review; and base-branch/detached-HEAD mechanics were
misleading. A test subject had to deviate from the literal cleanup instructions
to succeed, which exposed the sequencing bug.

Rewording or moving discard was rejected because any normal-menu placement
still advertises it. `git worktree remove --force` was also rejected: a dirty
worktree may contain unknown uncommitted work, so stopping loudly is the safer
behavior.

**Action:** audit this fork's copy for the `WORKTREE_PATH`-after-`cd`
sequencing bug specifically. That is a live defect, not a style preference.

---

### 3.10 Index-style Integration sections

**Upstream change:** PR #1932 (`obra`, merged 2026-07-13). Most bottom-of-file
Integration lists duplicated references already present at the decision point
and had become stale; requesting-code-review still described an older SDD flow.
More importantly, the audit found sole-carrier requirements in those indexes:
the isolated-workspace requirement for SDD/executing-plans and systematic
debugging's handoff to verification were stated nowhere else.

Rejected: *"Delete without moving anything: rejected — the worktree and
verification lines are sole carriers; deleting them silently drops real
requirements."*

**Action:** audit this fork's Integration sections for sole carriers **before**
deleting anything.

---

## Tier 4 — Skip

| Area | PRs | Reason |
|---|---|---|
| Gemini CLI support | #1846 (remove), #1959 (revert the removal) | Removed as *"EOLed by Google"*, then reverted. Unsettled upstream churn. |
| evals harness / submodule | #1488, #1541, ~10 bumps | This fork does not ship `evals/`. Upstream removed it in v6.0.2 because the *"evals submodule breaks plugin installs"* (#1778, #1774) — a trap this fork avoided by never adopting it. |
| Codex portal packaging | #1876, #1877, #1881, #1880 | Ships to OpenAI's Codex portal; not this fork's distribution path. |
| Kimi / Antigravity / Factory Droid / pi | #1673, #1657, #1137, #1499 | Harnesses this fork does not target. |
| Release + version + README + hiring | #1468, #1769, #1874, #2028, #1760, #2049 | Upstream release mechanics; this fork is on an independent v7.x line. |
| Delete `CHANGELOG.md` | #1163 | Upstream made `RELEASE-NOTES.md` its sole history. This fork actively maintains both files for its independent 7.x releases, so the upstream simplification would delete live fork history. |
| Contributor guidelines / disclosure | #1651, #1296 | Governance for a much larger contributor base. |
| Dangling anchor fix | #2010 | `antigravity-tools.md` is not shipped here. **But see the method note below.** |

**Method worth stealing from #2010:** while synchronizing a downstream fork,
the contributor ran a static check comparing every local anchor link with the
headings in its target file. It found the sole mismatch without needing a live
Antigravity session. That is a cheap CI check for a fork in exactly this
position.

That is a cheap CI check for a fork in exactly this position.

---

## Windows hooks — partially applicable

**Part already fine:** `hooks/hooks.json` routes through `run-hook.cmd`, so the
launcher portion of PR #1054 is present for the Claude path. The matcher is already
`startup|clear|compact`, so PR #1838's Codex drift does not apply (no
`hooks-codex.json` in this fork).

**Two gaps:**

1. `hooks/hooks.json` **lacks `"shell": "bash"`** on the SessionStart
   registration. PR #1993 (`obra`, fixes #1751, #1965, #1918):

   The PR reports that without Git Bash, PowerShell treats the leading quoted
   path as a string expression and then rejects the `session-start` token; older
   cmd.exe dispatch can also lose quoting when a profile path contains special
   characters such as parentheses. In both cases the bootstrap silently fails
   and skills stop auto-triggering. Both paths were reproduced on Windows 11.
   One-line fix.

2. `hooks/hooks-cursor.json` still calls `./hooks/session-start` directly.
   PR #1054 (`starumiQAQ`, #871):

   The PR shows that Windows does not execute the extensionless script as Unix
   does; it can open the system “Open with” dialog instead, so SessionStart
   never returns the bootstrap context.

   Fix: `./hooks/run-hook.cmd session-start`.

Both are only worth doing if this fork has Windows users.

---

## Legacy slash commands

**Fork state:** `commands/brainstorm.md`, `commands/execute-plan.md`,
`commands/write-plan.md` — all three are pure deprecation stubs whose entire
body is *"Tell your human partner that this command is deprecated and will be
removed in the next major release."*

**Upstream:** PR #1188 (`obra`) deleted all three because they had been
deprecated since 5.0.0.

This fork is at v7.4.0 — three major versions past the deprecation notice. Free
cleanup, unless something external still references the command names.

---

## Suggested order

| # | Work | Effort | Risk |
|---|---|---|---|
| 1 | Add Codex manifest `"hooks": {}` (1.0) | 1 line | none |
| 2 | `Ultrathink` → `Ultra-think` (1.4) | 1 char | none |
| 3 | Two `@`-link fixes (1.5) | 2 lines | none |
| 4 | `find-polluter.sh` prefix/empty/result-edge fixes (1.3) | small | low |
| 5 | Circle K + bare-`debugging` + `/Users/jesse` (2.2–2.4) | ~8 lines | none |
| 6 | Cache the OpenCode bootstrap (2.0) | small | low |
| 7 | Windows hook portability fixes | 2 lines | low |
| 8 | WS frame cap (1.1) | ~15 lines | low |
| 9 | **Brainstorm server hardening (1.2)** | large | medium — bring tests |
| 10 | Port `dispatching-parallel-agents` + `receiving-code-review` (2.5) | mechanical | low |
| 11 | Audit/fix `finishing-a-development-branch` (3.9) | medium | low |
| 12 | `writing-skills` form-selection section (3.7) | +33 lines | low |
| 13 | SDD evidence, scoping, read-only, and bounded fix loop (3.2/3.2a) | medium | medium |
| 14 | Merge `agents/code-reviewer.md` into the skill (3.5) | medium | low |
| 15 | Delete `commands/` (legacy stubs) | deletion | low |

Items 1–8 are bounded defects or portability fixes with cited evidence. Item 9
is the largest safety change and should land separately with the upstream
brainstorm-server tests adapted to this fork.

---

## Verification boundary

Recorded explicitly so a second reviewer knows where to push.

1. **Upstream's eval numbers are self-reported.** The n=5 / n=25 / 35-sample
   figures in #1717, #1934, #1741, #1943 come from the PR authors. They are
   quoted with their own caveats (the #1717 author's public correction, the
   low-confidence flag on `verification-before-completion`, and cchamplin's
   contradicting field report), but not independently reproduced here.

2. **No upstream code was executed.** Applicability was established by grepping
   this fork for the described defect, not by running upstream's tests.

3. **Every one of the 291 commits was accounted for, but not every changed line
   received the same depth of review.** The complete SHA/subject ledger is in
   Appendix A. Commits were inspected by subject, changed paths, patch status,
   initiative, and linked PR/issue/release evidence. Candidate changes on this
   fork's shared runtime and skill surfaces received targeted diffs; release
   bumps, evaluation artifacts, and unsupported-harness packaging were reviewed
   as groups.

4. **Harness manifests and tests were assessed for applicability, not executed.**
   `.opencode`, `.codex-plugin`, `.cursor-plugin`, hook manifests, and their
   relevant upstream tests were line-compared where they affect proposals in
   this document. That exposed the Codex empty-hooks defect, the OpenCode cache
   gap, and both Windows hook gaps. Upstream's full test matrices were not run.

5. **Tests should travel with manual ports.** In particular, the brainstorm
   server hardening should bring the upstream server/auth/lifecycle tests, the
   `find-polluter.sh` fix should bring its regression tests, and manifest/hook
   fixes should bring focused packaging/Windows assertions adapted to this
   fork's extra handoff hooks.

6. **No claim is made that this fork's own 82 commits are correct.** Only the
   shared surface was reviewed.

---

## Local follow-up checks resolved

- **The two code-review definitions have drifted substantially.**
  `agents/code-reviewer.md` is a generic 48-line persona; the skill-local
  `code-reviewer.md` is a 153-line Ruby/Rails-specific template with different
  placeholders and output rules. #1299's two-sources-of-truth problem is real
  here, not hypothetical.
- **The SDD loop is unbounded.** It says `Repeat until approved` and contains no
  round limit or controller adjudication. Reviewer findings go back to the same
  implementer, while a general subagent failure dispatches a fresh fix agent.
  The exact three-way upstream wording conflict is not present, but the
  pathological unbounded loop is.
- **The branch-finishing cleanup bug is present.** The skill checks the current
  branch only after merge/discard commands have checked out the base branch, so
  it can no longer identify the original worktree and cleanup silently skips.
  It also still advertises discard beside successful completion options and
  hardcodes `gh pr create`.
- **Integration sections do contain sole-carrier requirements.** The worktree
  prerequisite for `executing-plans` and SDD, and systematic debugging's
  verification handoff, are not stated at their actual decision points. Move
  them before pruning the index sections.
- **One policy choice remains:** this fork still offers
  `~/.config/superpowers/worktrees`. Upstream removed it because it confused
  users, but the Ruby fork may intentionally want a stable cross-project
  location. Decide that policy before rewriting the Rails/SQLite-aware worktree
  skill.

---

## Primary rationale sources

These are the upstream conversations used for integration decisions. Commit
links for every individual patch are in Appendix A.

| Area | Primary PR/comment or issue trail |
|---|---|
| Releases and rollups | [#1468](https://github.com/obra/superpowers/pull/1468), [#1769](https://github.com/obra/superpowers/pull/1769), [#1874](https://github.com/obra/superpowers/pull/1874), [#1897](https://github.com/obra/superpowers/pull/1897), [#2028](https://github.com/obra/superpowers/pull/2028) |
| Cross-harness runtime and packaging | [#910](https://github.com/obra/superpowers/pull/910), [#1054](https://github.com/obra/superpowers/pull/1054), [#1165](https://github.com/obra/superpowers/pull/1165), [issue #1202](https://github.com/obra/superpowers/issues/1202), [#1188](https://github.com/obra/superpowers/pull/1188), [#1993](https://github.com/obra/superpowers/pull/1993) |
| Worktrees and branch completion | [#1121](https://github.com/obra/superpowers/pull/1121), [#1124](https://github.com/obra/superpowers/pull/1124), [#1122](https://github.com/obra/superpowers/pull/1122), [#1476](https://github.com/obra/superpowers/pull/1476), [#1665](https://github.com/obra/superpowers/pull/1665), [#1933](https://github.com/obra/superpowers/pull/1933) |
| Brainstorm server security | [issue #1014](https://github.com/obra/superpowers/issues/1014), [#1555](https://github.com/obra/superpowers/pull/1555), [#1720](https://github.com/obra/superpowers/pull/1720) |
| SDD | [issue #994](https://github.com/obra/superpowers/issues/994), [#1065](https://github.com/obra/superpowers/pull/1065), [#1717](https://github.com/obra/superpowers/pull/1717), [issue #1538](https://github.com/obra/superpowers/issues/1538), [issue #1543](https://github.com/obra/superpowers/issues/1543), [issue #1780](https://github.com/obra/superpowers/issues/1780), [#1789](https://github.com/obra/superpowers/pull/1789), [#1943](https://github.com/obra/superpowers/pull/1943), [#1998](https://github.com/obra/superpowers/pull/1998) |
| Skill correctness and authoring | [#1299](https://github.com/obra/superpowers/pull/1299), [#1531](https://github.com/obra/superpowers/pull/1531), [#1532](https://github.com/obra/superpowers/pull/1532), [#1558](https://github.com/obra/superpowers/pull/1558), [#1601](https://github.com/obra/superpowers/pull/1601), [#1741](https://github.com/obra/superpowers/pull/1741), [#1847](https://github.com/obra/superpowers/pull/1847), [#1848](https://github.com/obra/superpowers/pull/1848), [#1932](https://github.com/obra/superpowers/pull/1932), [#1934](https://github.com/obra/superpowers/pull/1934), [#1935](https://github.com/obra/superpowers/pull/1935), [#2010](https://github.com/obra/superpowers/pull/2010), [#2011](https://github.com/obra/superpowers/pull/2011) |
| Contributor governance | [#1651](https://github.com/obra/superpowers/pull/1651), motivated by [issue #1647](https://github.com/obra/superpowers/issues/1647) |

---

## Appendix A — complete upstream commit ledger

The order is upstream ancestry order. “Already patch-equivalent” means the
same patch exists in this fork under another SHA; merge commits are listed but
are not independently classifiable by `git cherry`.

| Date | Commit | Subject | Patch status vs fork |
|---|---|---|---|
| 2026-03-25 | [`74a0c00`](https://github.com/obra/superpowers/commit/74a0c004eb2b0b2bb9c4e71aba4f3f6319b9d2aa) | docs: add Codex App compatibility design spec (PRI-823) | upstream-only |
| 2026-03-25 | [`33e9bea`](https://github.com/obra/superpowers/commit/33e9bea3cce015dceaf56d1449e46dfca6e3b00a) | docs: address spec review feedback for PRI-823 | upstream-only |
| 2026-03-25 | [`c28b28f`](https://github.com/obra/superpowers/commit/c28b28ffbd8adc1725e3e25a022d1421e15cab80) | docs: address team review feedback for PRI-823 spec | upstream-only |
| 2026-03-25 | [`80c0a45`](https://github.com/obra/superpowers/commit/80c0a45fcce85e0f1d6851b0d94a7638bdfdc5e9) | docs: clarify executing-plans in What Does NOT Change section | upstream-only |
| 2026-03-25 | [`eb2b44b`](https://github.com/obra/superpowers/commit/eb2b44b23f90ebc14d9773332fa6f8663f8fe6e9) | docs: add cleanup guard test (#5) and sandbox fallback test (#10) to spec | upstream-only |
| 2026-03-25 | [`bd080e3`](https://github.com/obra/superpowers/commit/bd080e3cc87a17f78fc53a2347510e410d147ab6) | docs: add implementation plan for Codex App compatibility (PRI-823) | upstream-only |
| 2026-03-25 | [`2b1bfe5`](https://github.com/obra/superpowers/commit/2b1bfe5db62e0b9bf1566a3c79e87608ea4cc5f5) | docs(codex-tools): add named agent dispatch mapping for Codex (#647) | already-patch-equivalent |
| 2026-03-25 | [`4fd9aa2`](https://github.com/obra/superpowers/commit/4fd9aa2dd5b602a102a1ff4743849642b73655c1) | fix(writing-skills): correct false 'only two fields' frontmatter claim (#882) | upstream-only |
| 2026-03-25 | [`e6221a4`](https://github.com/obra/superpowers/commit/e6221a48c54141e0ef04adaea4895a8150fc57a1) | Replace subagent review loops with lightweight inline self-review | already-patch-equivalent |
| 2026-03-25 | [`4ae1a3d`](https://github.com/obra/superpowers/commit/4ae1a3d6a6e1e2171ae9de0eb7daf3e192c2b792) | Revert "Replace subagent review loops with lightweight inline self-review" | upstream-only |
| 2026-03-25 | [`3f80f1c`](https://github.com/obra/superpowers/commit/3f80f1c769d8a172ee9803d049253f15fbe4895b) | Reapply "Replace subagent review loops with lightweight inline self-review" | already-patch-equivalent |
| 2026-03-25 | [`a1155f6`](https://github.com/obra/superpowers/commit/a1155f623fbf9ff321a064fe7a2714ffa68b97fc) | Add v5.0.6 release notes | upstream-only |
| 2026-03-25 | [`151cfb1`](https://github.com/obra/superpowers/commit/151cfb16a0901275e493b46fe591f391e91924ea) | Move brainstorm server metadata to .meta/ subdirectory | upstream-only |
| 2026-03-25 | [`9e6e077`](https://github.com/obra/superpowers/commit/9e6e077d33f2c0985e662e8d9239b51e9fb1cbf2) | Revert "Move brainstorm server metadata to .meta/ subdirectory" | upstream-only |
| 2026-03-25 | [`9e3ed21`](https://github.com/obra/superpowers/commit/9e3ed213a04315e57055d98ef8dd78bff6b63683) | Separate brainstorm server content and state into peer directories | upstream-only |
| 2026-03-25 | [`f076bd3`](https://github.com/obra/superpowers/commit/f076bd3431dd2826402bb91be7a8b95350a34515) | Fix owner-PID false positive when owner runs as different user | upstream-only |
| 2026-03-25 | [`9f04f06`](https://github.com/obra/superpowers/commit/9f04f0635114d09ca054778e2dd44942efd1c008) | Fix owner-PID lifecycle monitoring for cross-platform reliability | upstream-only |
| 2026-03-25 | [`eafe962`](https://github.com/obra/superpowers/commit/eafe962b18f6c5dc70fb7c8cc7e83e61f4cdde06) | Release v5.0.6: inline self-review, brainstorm server restructure, owner-PID fixes | upstream-only |
| 2026-03-31 | [`a2964d7`](https://github.com/obra/superpowers/commit/a2964d7a20b8d9fefafc14ded4b5416dd1d4246e) | fix: add Copilot CLI platform detection for sessionStart context injection | upstream-only |
| 2026-03-31 | [`8b16692`](https://github.com/obra/superpowers/commit/8b1669269c51835168c98fd435a7af1e5f15ec12) | feat: add Copilot CLI tool mapping, docs, and install instructions | upstream-only |
| 2026-03-31 | [`2d942f3`](https://github.com/obra/superpowers/commit/2d942f3b01cc636e2ef9ebfc50f05925df8ed3f6) | fix(opencode): align skills path across bootstrap, runtime, and tests | upstream-only |
| 2026-03-31 | [`65d760f`](https://github.com/obra/superpowers/commit/65d760f9c28b87c07b4748d2649189de85a79d36) | docs: add OpenCode path fix to release notes | upstream-only |
| 2026-03-31 | [`0a1124b`](https://github.com/obra/superpowers/commit/0a1124ba5368e830969fc1a1f30f84265711b8cd) | fix(opencode): inject bootstrap as user message instead of system message | upstream-only |
| 2026-03-31 | [`f0df5ec`](https://github.com/obra/superpowers/commit/f0df5eca3059feea3b92b49335ae264c3b3170a3) | docs: update release notes with OpenCode bootstrap change | upstream-only |
| 2026-03-31 | [`1f20bef`](https://github.com/obra/superpowers/commit/1f20bef3f59b85ad7b52718f822e37c4478a3ff5) | Release v5.0.7: Copilot CLI support, OpenCode fixes | upstream-only |
| 2026-03-31 | [`c0b417e`](https://github.com/obra/superpowers/commit/c0b417e40959a72899d46863a024dcb7baad7b76) | Add contributor guidelines to reduce agentic slop PRs | upstream-only |
| 2026-03-31 | [`dd23728`](https://github.com/obra/superpowers/commit/dd237283dbfe466e11bd4be55acf14ecb8f6636e) | Add agent-facing guardrails to contributor guidelines | upstream-only |
| 2026-04-01 | [`eeaf2ad`](https://github.com/obra/superpowers/commit/eeaf2ad15b5bc3b52ae9dda98c42418bf9a667b1) | Add release announcements link, consolidate Community section | upstream-only |
| 2026-04-01 | [`4b1b20f`](https://github.com/obra/superpowers/commit/4b1b20f69fd526895082eb97e657ff103d0bd35a) | Add detailed Discord description to Community section | upstream-only |
| 2026-04-01 | [`b7a8f76`](https://github.com/obra/superpowers/commit/b7a8f76985f1e93e75dd2f2a3b424dc731bd9d37) | Merge pull request #1029 from obra/readme-release-announcements | merge-or-unclassified |
| 2026-04-06 | [`a6b1a1f`](https://github.com/obra/superpowers/commit/a6b1a1fa0c367a7cf3d373e1bdb0dbc84d50ccde) | Update Discord invite link | upstream-only |
| 2026-04-06 | [`917e5f5`](https://github.com/obra/superpowers/commit/917e5f53b16b115b70a3a355ed5f4993b9f8b73d) | Fix Discord invite link | upstream-only |
| 2026-04-14 | [`a5d36b1`](https://github.com/obra/superpowers/commit/a5d36b130055ebfbaea48b685a43cc40fccf72a2) | chore: remove vestigial CHANGELOG.md | upstream-only |
| 2026-04-14 | [`8c8c5e8`](https://github.com/obra/superpowers/commit/8c8c5e87ce7baa85ad59d5bffc6b901c32b7badc) | adds tooling to mirror superpowers as a codex plugin with the appropriate metadata changes | upstream-only |
| 2026-04-14 | [`ac1c715`](https://github.com/obra/superpowers/commit/ac1c715ffb1563de58760d815ad10f52fcda0d6b) | rewrites sync tool to clone the fork, open a PR, and regenerate overlays inline | upstream-only |
| 2026-04-14 | [`a569527`](https://github.com/obra/superpowers/commit/a569527b89c152ac697d6c3ffec335d26769afdc) | Merge pull request #1163 from shaanmajid/chore/remove-stray-changelog | merge-or-unclassified |
| 2026-04-14 | [`da283df`](https://github.com/obra/superpowers/commit/da283df0582dcf55257b93340c3e432e3c88769f) | remove things we dont need | upstream-only |
| 2026-04-14 | [`777a977`](https://github.com/obra/superpowers/commit/777a9770d8c70cb1eab51f3a64dfa4d7fadbe951) | sync-to-codex-plugin: mirror CODE_OF_CONDUCT.md, drop agents/openai.yaml overlay | upstream-only |
| 2026-04-14 | [`6149f36`](https://github.com/obra/superpowers/commit/6149f3635ada80182895d586d803c48124524d7d) | sync-to-codex-plugin: align plugin.json heredoc with current live shape | upstream-only |
| 2026-04-14 | [`bcdd7fa`](https://github.com/obra/superpowers/commit/bcdd7fa24cc0729897462179e073afccf888f7c9) | sync-to-codex-plugin: exclude assets/, add --bootstrap flag | upstream-only |
| 2026-04-14 | [`bc25777`](https://github.com/obra/superpowers/commit/bc25777c6a144f6b2f595cf0de12b20d2d97ffc0) | sync-to-codex-plugin: anchor EXCLUDES patterns to source root | upstream-only |
| 2026-04-14 | [`f9b088f`](https://github.com/obra/superpowers/commit/f9b088f7b3a6fe9d9a9a98e392ad13c9d47053a4) | Merge pull request #1165 from obra/mirror-codex-plugin-tooling | merge-or-unclassified |
| 2026-04-15 | [`34c17ae`](https://github.com/obra/superpowers/commit/34c17aefb23c43960580b4a7f0ed5cb45c270cbe) | sync-to-codex-plugin: seed interface.defaultPrompt (#1180) | upstream-only |
| 2026-04-15 | [`c4bbe65`](https://github.com/obra/superpowers/commit/c4bbe651cb1bc5e7bec6f7effae2b946571f3258) | Some terminology cleanups | upstream-only |
| 2026-04-16 | [`a5dd364`](https://github.com/obra/superpowers/commit/a5dd364e42d90d05703605422dfba408db713af1) | README updates for Codex, other  cleanup | upstream-only |
| 2026-04-16 | [`99e4c65`](https://github.com/obra/superpowers/commit/99e4c656bf359eb1dae5e8bc0fbb095955d4ad83) | reorder installs | upstream-only |
| 2026-04-16 | [`9f42444`](https://github.com/obra/superpowers/commit/9f42444ab1b76d015fd554c2fa9a425174b1af0f) | formatting | upstream-only |
| 2026-04-16 | [`b557648`](https://github.com/obra/superpowers/commit/b55764852ac78870e65c6565fb585b6cd8b3c5c9) | formatting | upstream-only |
| 2026-04-23 | [`6efe32c`](https://github.com/obra/superpowers/commit/6efe32c9e2dd002d0c394e861e0529675d1ab32e) | Use committed Codex plugin files in sync script | upstream-only |
| 2026-04-30 | [`e7a2d16`](https://github.com/obra/superpowers/commit/e7a2d16476bf042e9add4699c9d018a90f86e4a6) | Require session transcript for new-harness PRs | upstream-only |
| 2026-05-04 | [`f2cbfbe`](https://github.com/obra/superpowers/commit/f2cbfbefebbfef77321e4c9abc9e949826bea9d7) | Release v5.1.0 (#1468) | upstream-only |
| 2026-05-29 | [`6fd4507`](https://github.com/obra/superpowers/commit/6fd4507659784c351abbd2bc264c7162cfd386dc) | Require contributors to disclose authoring environment and target dev | upstream-only |
| 2026-06-15 | [`8cf3900`](https://github.com/obra/superpowers/commit/8cf39006140a743dce31ba4046fceab90cc214e6) | Job posting | upstream-only |
| 2026-06-16 | [`718cb1d`](https://github.com/obra/superpowers/commit/718cb1d78c1d6963a13cbed03c84e71edf9a3403) | docs: turned the dash in "- Jesse" into an escape sequence (#1474) | upstream-only |
| 2026-06-16 | [`bce1267`](https://github.com/obra/superpowers/commit/bce1267adbb3813a3c95346a9c9d7bcd0e49ef0f) | Spec: lift drill into superpowers as evals/ | upstream-only |
| 2026-06-16 | [`09d2c1d`](https://github.com/obra/superpowers/commit/09d2c1d39c72c3cf27a13884a85a8b2dca6313d2) | Spec: address adversarial review findings | upstream-only |
| 2026-06-16 | [`1a42ead`](https://github.com/obra/superpowers/commit/1a42ead98f5f5d0ed8f6ab906ea11cb942f85caf) | Plan: lift drill into superpowers as evals/ | upstream-only |
| 2026-06-16 | [`6bc6f22`](https://github.com/obra/superpowers/commit/6bc6f2279dbc14f528829c37c22280fdb7b0a3d6) | Lift drill into evals/ at 013fcb8b7dbefd6d3fa4653493e5d2ec8e7f985b | upstream-only |
| 2026-06-16 | [`03cc20d`](https://github.com/obra/superpowers/commit/03cc20d3b593373b1c2fd7c21dbb04999f7921aa) | evals: default SUPERPOWERS_ROOT to parent of evals/ if unset | upstream-only |
| 2026-06-16 | [`671ec37`](https://github.com/obra/superpowers/commit/671ec3769d470d5df6bbb2b75c80409c364c6420) | evals: drop SUPERPOWERS_ROOT from codex/gemini required_env | upstream-only |
| 2026-06-16 | [`09046c0`](https://github.com/obra/superpowers/commit/09046c046b23486e707b0beebb7c6e777b3c426f) | evals: drop SUPERPOWERS_ROOT setup step from README/CLAUDE | upstream-only |
| 2026-06-16 | [`8611a4e`](https://github.com/obra/superpowers/commit/8611a4ea978f5c1971a26fe7fbff260b44a7d855) | tests: remove skill-triggering bash prompts (covered by drill triggering-* scenarios) | upstream-only |
| 2026-06-16 | [`7fd1ac7`](https://github.com/obra/superpowers/commit/7fd1ac7bfc694966e72bc6b6de8c8c200596b046) | tests: remove run-claude-describes-sdd.sh (covered by drill mid-conversation-skill-invocation) | upstream-only |
| 2026-06-16 | [`1f0ad38`](https://github.com/obra/superpowers/commit/1f0ad3817d03a4ba1b18d369e88104b97b9bcfcc) | tests: remove subagent-driven-dev fixtures (covered by drill sdd-go-fractals + sdd-svelte-todo) | upstream-only |
| 2026-06-16 | [`ea8aad8`](https://github.com/obra/superpowers/commit/ea8aad87645093f6e6b111cd75879f7a4dccdd99) | tests: remove test-document-review-system.sh (covered by drill spec-reviewer-catches-planted-flaws) | upstream-only |
| 2026-06-16 | [`12ef68d`](https://github.com/obra/superpowers/commit/12ef68d55ecad3f2304e00099bb5137734684150) | tests: remove test-requesting-code-review.sh (covered by drill code-review-catches-planted-bugs) | upstream-only |
| 2026-06-16 | [`315ef09`](https://github.com/obra/superpowers/commit/315ef09ebcd4faddc2b3689621c627ba734ad9f9) | tests: annotate three kept bash tests with drill coverage notes | upstream-only |
| 2026-06-16 | [`342ccf6`](https://github.com/obra/superpowers/commit/342ccf61d1d7ff846fc615ca10eccfc947007396) | docs: annotate dated artifacts referencing lifted bash tests | upstream-only |
| 2026-06-16 | [`0e7b967`](https://github.com/obra/superpowers/commit/0e7b967e69c954c174ad02edbb3690ad4a10c206) | docs: introduce evals/ as the canonical skill-behavior eval harness | upstream-only |
| 2026-06-16 | [`a325106`](https://github.com/obra/superpowers/commit/a32510650245ed1cdaa22d6152314196fd8fe38d) | Address adversarial review findings | upstream-only |
| 2026-06-16 | [`74cddb5`](https://github.com/obra/superpowers/commit/74cddb5575345539c1bf95f2b54b47543136adc9) | evals: remove unreleased wave scenarios | upstream-only |
| 2026-06-16 | [`f7705f2`](https://github.com/obra/superpowers/commit/f7705f208e634995a20f7345b8cdd871cc092d4d) | evals: drop drill source marker | upstream-only |
| 2026-06-16 | [`9efbb7d`](https://github.com/obra/superpowers/commit/9efbb7dd0d96bcca1a2bd0ea4f200a93f30a7d38) | evals: add Gemini 2.5 Flash backend | upstream-only |
| 2026-06-16 | [`bc2558c`](https://github.com/obra/superpowers/commit/bc2558c3f9f097fcd84a6d3eb7924389eaebc378) | evals: use pre-commit hooks | upstream-only |
| 2026-06-16 | [`fb1dfe9`](https://github.com/obra/superpowers/commit/fb1dfe9a16c818291ab384ef41df999b1cb03bd2) | fix(writing-skills): use markdown link for testing methodology reference | upstream-only |
| 2026-06-16 | [`98e39bd`](https://github.com/obra/superpowers/commit/98e39bd9e47d59088bbe12071be36905665970ab) | fix: remove stale Cursor plugin refs | upstream-only |
| 2026-06-16 | [`ce95985`](https://github.com/obra/superpowers/commit/ce95985094fdf12cf32b9f77e6439bfc9140c9c6) | fix(using-git-worktrees): repair skipped Step 2 numbering (#1522) | upstream-only |
| 2026-06-16 | [`d00f4ad`](https://github.com/obra/superpowers/commit/d00f4ad4428e99db18619e077b99340fb7158f2f) | fix: remove global worktree path fallback (#1476) | upstream-only |
| 2026-06-16 | [`0fad59e`](https://github.com/obra/superpowers/commit/0fad59e91fe8ec56e700c33d167c84e031f7d0a5) | [codex] replace Circle K signal with generic review guidance (#1531) | upstream-only |
| 2026-06-16 | [`9ea7e2b`](https://github.com/obra/superpowers/commit/9ea7e2b6cb27161545e8d906aebd831d5311f5dd) | fix(tdd): link testing anti-patterns reference (#1532) | upstream-only |
| 2026-06-16 | [`741c232`](https://github.com/obra/superpowers/commit/741c2327682f0df7697b996b522c20f57c8080a2) | Move eval harness to submodule (#1541) | upstream-only |
| 2026-06-16 | [`f0e5117`](https://github.com/obra/superpowers/commit/f0e5117fa6bdd2645485d2a8df8d7a107c4bf2af) | Phase A: agent-neutral prose + CSO → SDO + spec | upstream-only |
| 2026-06-16 | [`6b9f1b2`](https://github.com/obra/superpowers/commit/6b9f1b214ab28a75677a9072d9333075971c333d) | Phase B: config-file refs + per-platform tool refs + spec | upstream-only |
| 2026-06-16 | [`1681f58`](https://github.com/obra/superpowers/commit/1681f58a3fb528791991253faec6bc9a8763a208) | Phase C: alphabetize README platform listings + spec | upstream-only |
| 2026-06-16 | [`6ec8686`](https://github.com/obra/superpowers/commit/6ec8686477cb4408a0de15a7eceedda809428318) | Phase D: cross-runtime tweaks (visual-companion, executing-plans, test) | upstream-only |
| 2026-06-16 | [`d7f47d3`](https://github.com/obra/superpowers/commit/d7f47d350a5fb53014af8bd707420c811f82ac1f) | Phase E: action-language tool vocabulary | upstream-only |
| 2026-06-16 | [`f030d6e`](https://github.com/obra/superpowers/commit/f030d6ef88ae28946184d87f7d339743da757651) | Tighten cross-platform tool references | upstream-only |
| 2026-06-16 | [`17a0cf1`](https://github.com/obra/superpowers/commit/17a0cf12fa307d248ebd1b334b829310c4d425ad) | docs: plan pi extension and evals work | upstream-only |
| 2026-06-16 | [`71ac601`](https://github.com/obra/superpowers/commit/71ac601627b4cc6b0507839640732b52a3541033) | feat: add pi superpowers package extension | upstream-only |
| 2026-06-16 | [`3406f5d`](https://github.com/obra/superpowers/commit/3406f5d80f8b7eccbf6b30a465bf91b00bd6c94c) | chore: keep pi extension under .pi | upstream-only |
| 2026-06-16 | [`db0396a`](https://github.com/obra/superpowers/commit/db0396a7dbf36ffdce8131e279e39cccb024c971) | Bump evals submodule for Pi backend | upstream-only |
| 2026-06-16 | [`295219a`](https://github.com/obra/superpowers/commit/295219a6fa730de4a6853838ca9b1d97afddb62d) | Align Pi mapping with action vocabulary | upstream-only |
| 2026-06-16 | [`1e7cd98`](https://github.com/obra/superpowers/commit/1e7cd987d3e0ca8fa3ab52d75f4e658e46694a3a) | [codex] support native Codex plugin hooks (#1540) | upstream-only |
| 2026-06-16 | [`94b5435`](https://github.com/obra/superpowers/commit/94b543561703fda6357ea78b7abf7d58a0a00816) | Bump superpowers-evals submodule | upstream-only |
| 2026-06-16 | [`b0a0872`](https://github.com/obra/superpowers/commit/b0a087277468ed2ab5f83ac13ef96876c9fe238e) | @mhat reported that his claude got confused about 'debugging' being named as a skill in the bootstrap | upstream-only |
| 2026-06-16 | [`8ed7c49`](https://github.com/obra/superpowers/commit/8ed7c499b37cd4000c2ca0f29f4148526664dd07) | Scope spec reviewer to task diff and make reviewers read-only | upstream-only |
| 2026-06-16 | [`3cd2db9`](https://github.com/obra/superpowers/commit/3cd2db9f8aa48cf7907c55adfaef2db540702209) | Convert curly to square brackets in code-reviewer.md placeholders | upstream-only |
| 2026-06-16 | [`95aa3d5`](https://github.com/obra/superpowers/commit/95aa3d5007882905418acc6f6dec3afd6bfd2b09) | Align windows-lifecycle test with current brainstorm server layout | upstream-only |
| 2026-06-16 | [`a318a5f`](https://github.com/obra/superpowers/commit/a318a5f621e7beaa5ab9c98e3c92a6b7c5bea6c1) | Make visual-companion.md script paths skill-rooted, not plugin-rooted | upstream-only |
| 2026-06-16 | [`90e1721`](https://github.com/obra/superpowers/commit/90e1721817ff783a200017e395911b9af858285a) | fix(systematic-debugging): defuse Claude Code ultrathink keyword scanner trigger (#1558) | upstream-only |
| 2026-06-16 | [`d72560e`](https://github.com/obra/superpowers/commit/d72560e462a74e10d161b7f993d5fc3282bfa1e2) | Pipe SessionStart hook printf through cat to absorb EPIPE on Windows | upstream-only |
| 2026-06-16 | [`ce86e63`](https://github.com/obra/superpowers/commit/ce86e63eb6a22cbf543bb9780d3cc604466aa466) | Probe per-user Git Bash and Scoop before falling back to PATH on Windows | upstream-only |
| 2026-06-16 | [`c676d36`](https://github.com/obra/superpowers/commit/c676d3639d25317d8ec265fd78f1e7e4762715fa) | Revert "Probe per-user Git Bash and Scoop before falling back to PATH on Windows" | upstream-only |
| 2026-06-16 | [`8ca7d21`](https://github.com/obra/superpowers/commit/8ca7d218d00829111533853ecc8358dc6399f784) | Revert "Make visual-companion.md script paths skill-rooted, not plugin-rooted" | upstream-only |
| 2026-06-16 | [`18726fe`](https://github.com/obra/superpowers/commit/18726fe0a39f1d539d4331a42cf8579c3e997bee) | fix(sync-to-codex-plugin): exclude /.pi/ so the pi extension doesn't leak into the Codex plugin | upstream-only |
| 2026-06-16 | [`3608167`](https://github.com/obra/superpowers/commit/3608167e0598b204e9ef219cdce0712ff515746b) | docs: add 'Porting Superpowers to a New Harness' guide | upstream-only |
| 2026-06-16 | [`36ce0a2`](https://github.com/obra/superpowers/commit/36ce0a21e409cfb3be498fae52e01a70589a04a6) | feat: add Antigravity CLI (agy) support | upstream-only |
| 2026-06-16 | [`24ae4c8`](https://github.com/obra/superpowers/commit/24ae4c800109494cb2fe06c110dd9f0da023de89) | fix(finishing-a-development-branch): detect remote platform before creating PR/MR | upstream-only |
| 2026-06-16 | [`4e3707f`](https://github.com/obra/superpowers/commit/4e3707fbbe648b5599c0b65080f053bfca7552a1) | fix(finishing-a-development-branch): remove gh-specific PR creation instruction | upstream-only |
| 2026-06-16 | [`48696e6`](https://github.com/obra/superpowers/commit/48696e651946d762fb3a750f2ffc510dcd6777d6) | fix: foreground mode saves node PID and clears OWNER_PID on Windows/MSYS2 | upstream-only |
| 2026-06-16 | [`3d07257`](https://github.com/obra/superpowers/commit/3d0725756c61d3d8c826b708880db865e6299052) | docs(windows): update polyglot hook docs | upstream-only |
| 2026-06-16 | [`4548b69`](https://github.com/obra/superpowers/commit/4548b69c60d7ad608f794eed3c9944da3fb94462) | docs(windows): trim polyglot hook implementation copy | upstream-only |
| 2026-06-16 | [`afbf0fc`](https://github.com/obra/superpowers/commit/afbf0fcfac1ac204ea13657cae53db3c26f9adcf) | feat(subagent-dev): add TDD RED evidence to implementer report format | upstream-only |
| 2026-06-16 | [`9f798e4`](https://github.com/obra/superpowers/commit/9f798e4a9e714532152fe0300384ec957cae238c) | feat: add Kimi Code plugin manifest | upstream-only |
| 2026-06-16 | [`e15d4ec`](https://github.com/obra/superpowers/commit/e15d4ecd88f4e9dae5c12488189438ab95c1d770) | fix: align Kimi manifest with supported fields | upstream-only |
| 2026-06-16 | [`f61300e`](https://github.com/obra/superpowers/commit/f61300eac8d85d055eb9afed870051ccdfb62f31) | fix: wire Kimi plugin into release metadata | upstream-only |
| 2026-06-16 | [`e47add1`](https://github.com/obra/superpowers/commit/e47add1dba9b8554c99d614930e629dbc136757d) | docs: simplify Kimi README install steps | upstream-only |
| 2026-06-16 | [`c877866`](https://github.com/obra/superpowers/commit/c8778664cd3d9e0c2d7c13934ce5ebd3c14e01ec) | docs: restore Kimi direct install command | upstream-only |
| 2026-06-16 | [`2c2e2bc`](https://github.com/obra/superpowers/commit/2c2e2bcbd4105c4a870163855e8254644a66672f) | Tighten Kimi plugin porting coverage | upstream-only |
| 2026-06-16 | [`21b44e4`](https://github.com/obra/superpowers/commit/21b44e44d32c7eeaaedb9996a5ce06a11430bbbc) | Add shell lint script | upstream-only |
| 2026-06-16 | [`d9d3d99`](https://github.com/obra/superpowers/commit/d9d3d99245f0f969ab85c1dd3eadda71001abb99) | fix(brainstorming): cap websocket frame payloads | upstream-only |
| 2026-06-16 | [`657174a`](https://github.com/obra/superpowers/commit/657174abdbd74c3fcdac112134b6a3b85aea0d24) | chore(evals): bump submodule to antigravity rate-limit fix (79f9963) | upstream-only |
| 2026-06-16 | [`7813867`](https://github.com/obra/superpowers/commit/7813867bbcefa0a3eda2e17b184508582b62d276) | chore(evals): bump submodule to --scenarios filter (ff3ee83) | upstream-only |
| 2026-06-16 | [`c8fc004`](https://github.com/obra/superpowers/commit/c8fc00435b758b64fc9901755ca191ea0089540d) | chore(evals): bump submodule for Claude Haiku target | upstream-only |
| 2026-06-16 | [`cbc8273`](https://github.com/obra/superpowers/commit/cbc8273bdd84169116cebdb226b795ba3452a52d) | feat(writing-skills): form-selection table + micro-test wording method | upstream-only |
| 2026-06-16 | [`fdb0f42`](https://github.com/obra/superpowers/commit/fdb0f4259582bcfec7c2ec6b7368841908a1b3e7) | fix(writing-skills): scope empirical claims, honest noise reporting, conditionalize micro-test checklist line | upstream-only |
| 2026-06-16 | [`1aa45d2`](https://github.com/obra/superpowers/commit/1aa45d20d25a1db2cfa114a48c313c44839e875b) | fix(writing-skills): hang backfire mechanism on the separated prohibition-vs-recipe comparison (NEW-4); control comparison stated as trend | upstream-only |
| 2026-06-16 | [`565845f`](https://github.com/obra/superpowers/commit/565845f251495cd041de2dedef37917bb5b6805b) | chore(evals): bump submodule to SUP-333 boundary + plumbing scenarios (7f8e80c) | upstream-only |
| 2026-06-16 | [`2b108b7`](https://github.com/obra/superpowers/commit/2b108b7dc2896df01a58384a3ff46e71ba04e9e2) | fix(brainstorm-server): ignore macOS resource-fork dotfiles | upstream-only |
| 2026-06-16 | [`5ddce06`](https://github.com/obra/superpowers/commit/5ddce063df0b018ef1e972177919b302d1c3430e) | fix(brainstorm-server): verify PID ownership before stopping | upstream-only |
| 2026-06-16 | [`56757f6`](https://github.com/obra/superpowers/commit/56757f68773fc83a481266ebef4b1c3df16452a5) | feat(brainstorm-server): 4h configurable idle timeout; close WS on shutdown | upstream-only |
| 2026-06-16 | [`36ac3e1`](https://github.com/obra/superpowers/commit/36ac3e1336065703cd518e9bf5e0a31ffdfb4046) | feat(brainstorm-companion): resilient reconnect, live status, paused overlay | upstream-only |
| 2026-06-16 | [`dd9fcc2`](https://github.com/obra/superpowers/commit/dd9fcc21ee08c36b66ca7d730abd28f679ccf1f5) | feat(brainstorm-server): reuse the same port on session restart | upstream-only |
| 2026-06-16 | [`463dfb7`](https://github.com/obra/superpowers/commit/463dfb7fd4737e51c2a17d5beae6b4e510f88b6f) | feat(brainstorm-server): opt-in auto-open of the browser on the first screen | upstream-only |
| 2026-06-16 | [`5a0f895`](https://github.com/obra/superpowers/commit/5a0f895387c53e26148db5b81c4f62368e262174) | feat(brainstorming): offer the visual companion just-in-time; harden lifecycle guidance | upstream-only |
| 2026-06-16 | [`fb08947`](https://github.com/obra/superpowers/commit/fb08947dedcb206dc783188951c17f18a0cbc399) | fix(brainstorm-server): address adversarial review findings | upstream-only |
| 2026-06-16 | [`7c805f3`](https://github.com/obra/superpowers/commit/7c805f34d2e8bc57837d81891dd0eb3859c6f371) | fix(brainstorm-server): tie stop-server PID check to the session's port | upstream-only |
| 2026-06-16 | [`09b6b25`](https://github.com/obra/superpowers/commit/09b6b25e089fdb5d27c852a1a2d4b2816442b1c8) | docs(brainstorm): catalog visual companion issues; choose session-key for security | upstream-only |
| 2026-06-16 | [`cb5bb88`](https://github.com/obra/superpowers/commit/cb5bb885fd7cf00a1820f20d922df06ec02d4bed) | feat(brainstorm-server): gate every endpoint behind a per-session key | upstream-only |
| 2026-06-16 | [`01de367`](https://github.com/obra/superpowers/commit/01de36703dcef42c9c5c5eafa840fb6cd8bcb29a) | test(brainstorm-server): thread session key through tests after auth merge | upstream-only |
| 2026-06-16 | [`7fbae02`](https://github.com/obra/superpowers/commit/7fbae0252fe90778ce0c06fde3bf5f87aa396fc2) | fix(brainstorm-server): fix auth-integration bugs from full-branch review | upstream-only |
| 2026-06-16 | [`83b5d3a`](https://github.com/obra/superpowers/commit/83b5d3a963ed63d8231ecb3276c8368caf1857a3) | Document visual companion auth hardening plan | upstream-only |
| 2026-06-16 | [`b17d54f`](https://github.com/obra/superpowers/commit/b17d54f839831b2345aa389e2f65f435f3a82867) | Harden brainstorm companion auth regressions | upstream-only |
| 2026-06-16 | [`69270c9`](https://github.com/obra/superpowers/commit/69270c9007d9f68ab2ea8867eff409fbcff58dd6) | Harden companion Windows lifecycle coverage | upstream-only |
| 2026-06-16 | [`ce6be66`](https://github.com/obra/superpowers/commit/ce6be66c875475360416e79ce59d234246504ad8) | Document visual companion final hardening fixup | upstream-only |
| 2026-06-16 | [`92a0a7a`](https://github.com/obra/superpowers/commit/92a0a7acc05a014b2dee3f8a605d23048500dead) | Tighten visual companion hardening spec | upstream-only |
| 2026-06-16 | [`d9ec119`](https://github.com/obra/superpowers/commit/d9ec1196b80a02e5fa66615ca9ea7e1b779344b2) | Plan visual companion final hardening fixup | upstream-only |
| 2026-06-16 | [`0410679`](https://github.com/obra/superpowers/commit/04106797576d0caa9daecab7d4681d21addfbcf7) | Harden root screen containment | upstream-only |
| 2026-06-16 | [`85914fb`](https://github.com/obra/superpowers/commit/85914fbcf89602a966989db673636f391aa355e1) | Fix server test fallback cleanup | upstream-only |
| 2026-06-16 | [`8f2525a`](https://github.com/obra/superpowers/commit/8f2525a80324106802d447af4f4dbae649dd4be6) | Isolate companion fallback tokens | upstream-only |
| 2026-06-16 | [`6bc49f0`](https://github.com/obra/superpowers/commit/6bc49f0183d34885b8125611998a19fddba727b7) | Harden companion stop ownership proof | upstream-only |
| 2026-06-16 | [`3402d4e`](https://github.com/obra/superpowers/commit/3402d4e7d749b168d742c386549d464d98b54a8f) | Fix companion lifecycle test ownership metadata | upstream-only |
| 2026-06-16 | [`51323e4`](https://github.com/obra/superpowers/commit/51323e4c64cc2e75ddfc497b57f6803bc5f9ebf8) | Harden companion platform tests | upstream-only |
| 2026-06-16 | [`69ed41a`](https://github.com/obra/superpowers/commit/69ed41af9e8f6bdb91c518c1809352aa4395c870) | Fix companion test cleanup and argv assertions | upstream-only |
| 2026-06-16 | [`fd9972a`](https://github.com/obra/superpowers/commit/fd9972a4bdcea9581cea0556d36df9c1c1b76b58) | Align visual companion docs with shipped scope | upstream-only |
| 2026-06-16 | [`2a8479b`](https://github.com/obra/superpowers/commit/2a8479b21d88e1b7c17f86290c531742092d1ae4) | Fix Windows lifecycle validation | upstream-only |
| 2026-06-16 | [`1c80914`](https://github.com/obra/superpowers/commit/1c80914052d7b180d722450765fc86be0839c34a) | Harden Windows browser launcher | upstream-only |
| 2026-06-16 | [`3a907d6`](https://github.com/obra/superpowers/commit/3a907d6a0a033eee1f6a3abce27fe97dbc2133e4) | Fix companion stop metadata and token permissions | upstream-only |
| 2026-06-16 | [`bfa2115`](https://github.com/obra/superpowers/commit/bfa21156f2244a64c4f68518ad0843b0248c5a4d) | chore: bump evals submodule to claude transcript-capture fix | upstream-only |
| 2026-06-16 | [`b04645d`](https://github.com/obra/superpowers/commit/b04645dc374ec6e115ad497a203f20b33fd6abcf) | Add design spec: task-scoped review dispatch for SDD | upstream-only |
| 2026-06-16 | [`1649580`](https://github.com/obra/superpowers/commit/16495807499e4501bcb0bb831ecf4799d9e7c764) | Harden review-dispatch spec per adversarial review findings | upstream-only |
| 2026-06-16 | [`61e2b82`](https://github.com/obra/superpowers/commit/61e2b82367838597c836fbaadb2bb7df1f3efcc3) | Add implementation plan for task-scoped review dispatch | upstream-only |
| 2026-06-16 | [`d1a14e3`](https://github.com/obra/superpowers/commit/d1a14e37eb98fed5e43ae9d98ed7019eecfd4d02) | Make per-task quality reviewer prompt self-contained and task-scoped | upstream-only |
| 2026-06-16 | [`12ed80e`](https://github.com/obra/superpowers/commit/12ed80e8cabac5a575a9b2244b22903395557df0) | Use bare placeholder names in quality reviewer prompt body | upstream-only |
| 2026-06-16 | [`342f4e2`](https://github.com/obra/superpowers/commit/342f4e2f21957041875ce5ffa7f737043b2c7be2) | Spec reviewer: judge from the diff, grounded skepticism, ⚠️ verdict channel | upstream-only |
| 2026-06-16 | [`bf46da2`](https://github.com/obra/superpowers/commit/bf46da2472bfa514d86e44ce79b656c9988a0c6b) | Scope spec reviewer's Your Job wording to the diff | upstream-only |
| 2026-06-16 | [`cc62053`](https://github.com/obra/superpowers/commit/cc6205389c4b3f05f06dc0d330d56a777e5f6aa8) | Implementer prompt: re-run covering tests after fixing review findings | upstream-only |
| 2026-06-16 | [`16da215`](https://github.com/obra/superpowers/commit/16da2152703a147401289ce300c2b655fcbc2467) | SDD controller: reviewer prompt budgets, ⚠️ handling, final-review pointer, model judgment | upstream-only |
| 2026-06-16 | [`4265301`](https://github.com/obra/superpowers/commit/42653013d98e3b6933f279dcc621621d8d01df25) | Sync plan's Task 5 blocks with review fixes | upstream-only |
| 2026-06-16 | [`16eaa8a`](https://github.com/obra/superpowers/commit/16eaa8a158a13a5c13d4cd7cee8f5f665a352627) | Fix plan doc: correct Task 1 grep expectation; sync Task 5 story block | upstream-only |
| 2026-06-16 | [`acb7465`](https://github.com/obra/superpowers/commit/acb746544d774bdf79ef35993a07b39263482eb6) | Sync plan: escaped pre() pattern in Task 5 checks block | upstream-only |
| 2026-06-16 | [`8335498`](https://github.com/obra/superpowers/commit/83354984edd642b97d5d7b7f570936ebc79fd6b4) | Forbid controllers pre-judging reviewer findings | upstream-only |
| 2026-06-16 | [`b42a232`](https://github.com/obra/superpowers/commit/b42a2321928a4ba3dda41bd22c2a0cafcd4ef88c) | Require explicit model on subagent dispatch | upstream-only |
| 2026-06-16 | [`62b1682`](https://github.com/obra/superpowers/commit/62b16823998a51a1c9e170e53464673cb5236880) | Close three review blind spots found by defect tracing | upstream-only |
| 2026-06-16 | [`0974229`](https://github.com/obra/superpowers/commit/09742294183a27157dee142d2b9efebba93efc98) | Red Flags: never tell a reviewer what not to flag or pre-rate severity | upstream-only |
| 2026-06-16 | [`d55cdce`](https://github.com/obra/superpowers/commit/d55cdce32cd2b78cb0ab9bc8ebb0170c03401032) | Add phrase-level pre-judging triggers to reviewer prompt rule | upstream-only |
| 2026-06-16 | [`5e03007`](https://github.com/obra/superpowers/commit/5e03007c85d461d38e9c014550055ed325560afe) | Cut review-cost drivers: turn-aware models, inline diffs, scoped evidence | upstream-only |
| 2026-06-16 | [`e08ad06`](https://github.com/obra/superpowers/commit/e08ad0660ac9a54e141cc99675e40205c8ca632b) | Merge per-task reviews into one task reviewer (iteration 2) | upstream-only |
| 2026-06-16 | [`097ed59`](https://github.com/obra/superpowers/commit/097ed5920f4f167af71029e4e1a1b0a97b2e3319) | Spec: document cost iterations and the per-task review consolidation | upstream-only |
| 2026-06-16 | [`c73e9a9`](https://github.com/obra/superpowers/commit/c73e9a9a3fa9704c9ee42c949916023319a8cbdf) | Close the Minor-severity escape hatch | upstream-only |
| 2026-06-16 | [`84d033e`](https://github.com/obra/superpowers/commit/84d033e9678cb0e0aee46b5483e902a4b4f34a2f) | Make diff-pasting non-optional for task reviewer dispatch | upstream-only |
| 2026-06-16 | [`3280a32`](https://github.com/obra/superpowers/commit/3280a322596cb4d9998a4f14f6f81839d9ddbcf9) | Reviewer skepticism covers the implementer's design rationales | upstream-only |
| 2026-06-16 | [`ee65656`](https://github.com/obra/superpowers/commit/ee656563c91886455c598b8c65532fde026e1785) | Hand reviewers the diff as a file, not a paste | upstream-only |
| 2026-06-16 | [`aa80399`](https://github.com/obra/superpowers/commit/aa803993554f3b417ca52a13827854be9e30effc) | Spec: record iterations 2-3 results and final frozen-config matrix | upstream-only |
| 2026-06-16 | [`68c9ddb`](https://github.com/obra/superpowers/commit/68c9ddb870c36595f81fd4d920e043817f3736a6) | Describe the review design as current state, not as a delta | upstream-only |
| 2026-06-16 | [`c30d822`](https://github.com/obra/superpowers/commit/c30d822efed5c4c4a83affd44d0f8dd81992b28c) | Add review-package script; close fix-dispatch test gap | upstream-only |
| 2026-06-16 | [`d7a8c07`](https://github.com/obra/superpowers/commit/d7a8c07fe3286a0d20b3363a3f68f2378d2d5f36) | Shared: unique review-package collateral names | upstream-only |
| 2026-06-16 | [`69a0035`](https://github.com/obra/superpowers/commit/69a00350ff2de6db58c9d07d59362bc7d3a6a561) | Spec: positive-instruction redesign — audit results, micro-test method, writing-plans variants | upstream-only |
| 2026-06-16 | [`4298eac`](https://github.com/obra/superpowers/commit/4298eac856d8823f8f435b10937505a115921f89) | Land eval-tuned combo: file handoffs, progress ledger, final-review package, REQUIRED model lines, reviewer risk budget | upstream-only |
| 2026-06-16 | [`e9b88d0`](https://github.com/obra/superpowers/commit/e9b88d05c8da1e75f7375bd58236d951e133994e) | Adopt audited positive phrasings: evidence rule leads positive; fix-report completeness as checklist | upstream-only |
| 2026-06-16 | [`b2872a4`](https://github.com/obra/superpowers/commit/b2872a4a662e070314c724574a826ee833efe4ba) | Spec: record iterations 4-5 (variance honesty, structural fixes, final validated ranges) | upstream-only |
| 2026-06-16 | [`d3dd1ec`](https://github.com/obra/superpowers/commit/d3dd1ecc7d91b958245bd1b728873ccf4bc09f95) | Record writing-plans micro-test result: resolved, no change needed | upstream-only |
| 2026-06-16 | [`30bbeef`](https://github.com/obra/superpowers/commit/30bbeefe892c4221c5ffa990d009abc27258d005) | Spec: strict-cost SDD experiment ladder — judgment as co-invariant, plan-side crispness first | upstream-only |
| 2026-06-16 | [`b5b3b5d`](https://github.com/obra/superpowers/commit/b5b3b5d99c47560840ed89ce3222b851a17b0e47) | Strict-cost spec: record batch A-E rung verdicts (L1 validated, L2 recon positive, L3 dead) | upstream-only |
| 2026-06-16 | [`f5e8df4`](https://github.com/obra/superpowers/commit/f5e8df425264a44e85f28c982972617dbf120eb7) | Strict-cost spec: L2 recon n=2 (sonnet controller $6.68/$8.05, judgment clean, escalation points unstressed) | upstream-only |
| 2026-06-16 | [`25192df`](https://github.com/obra/superpowers/commit/25192df30bdc098768f657eed4e7e92392c6ae6a) | Strict-cost spec: L1 final — cost win re-attributed to complete-code plans; guidance owns fidelity/variance | upstream-only |
| 2026-06-16 | [`de4672b`](https://github.com/obra/superpowers/commit/de4672b171213a6ff6960228d8b95c46ea0b09f4) | Constraints block is the reviewer's attention lens: copy spec verbatim, never improvise process rules | upstream-only |
| 2026-06-16 | [`8e1262a`](https://github.com/obra/superpowers/commit/8e1262a3bae92b640d87fa81c51c53b65e490590) | writing-plans: task right-sizing, Global Constraints header, per-task Interfaces blocks | upstream-only |
| 2026-06-16 | [`8bcefb1`](https://github.com/obra/superpowers/commit/8bcefb12cb7b82a8416761079d1e9dc06ad197e3) | Strict-cost spec: L2 final — died at gates; explicit escalation holds at sonnet, implicit adjudication does not | upstream-only |
| 2026-06-16 | [`cfe48c2`](https://github.com/obra/superpowers/commit/cfe48c28acb14f55c55cc20c9630e49cd8c3663f) | E03: cheapest-tier implementers when plan carries complete code (transcription hypothesis) | upstream-only |
| 2026-06-16 | [`e97faaf`](https://github.com/obra/superpowers/commit/e97faafb5a9ffd9ac8448a67f5c5c1fae1c55c48) | E27 stack: conditional impl tier + final-review tier pin + narration recipe + terse reviewer contract | upstream-only |
| 2026-06-16 | [`530476f`](https://github.com/obra/superpowers/commit/530476fd00b6c9a8107f8a74951f1ed781ae4144) | L2b: plan-mandated defects are findings the human adjudicates | upstream-only |
| 2026-06-16 | [`be40020`](https://github.com/obra/superpowers/commit/be400204b345c805c70c1df1223ddc971133822d) | Spec: L2b tested — opus structural win, sonnet transmission+attention gap (E35/E36); bump evals to 9919b27 | upstream-only |
| 2026-06-16 | [`b61b550`](https://github.com/obra/superpowers/commit/b61b55013ae1ff26fb989f9d08a8ffd563685334) | E37: pre-flight plan review — surface plan conflicts as one batched question before Task 1 | upstream-only |
| 2026-06-16 | [`9c61797`](https://github.com/obra/superpowers/commit/9c61797773ffbc89f5181b05e1f97a53bb0f8f37) | Draft Superpowers 6 release notes | upstream-only |
| 2026-06-16 | [`b3ee712`](https://github.com/obra/superpowers/commit/b3ee712d3a68b604b3f36d872c7ec91501197dcb) | Add visual companion Prime Radiant branding | upstream-only |
| 2026-06-16 | [`c5a9651`](https://github.com/obra/superpowers/commit/c5a965101bdd0c1a41ada3e9b0e0c075106ad5d4) | Bump version to 6.0.0 | upstream-only |
| 2026-06-16 | [`77879bb`](https://github.com/obra/superpowers/commit/77879bbb91d7c6cf0d923be6fb2e764032008303) | Bump evals submodule: unify per-agent bootstrap scenarios | upstream-only |
| 2026-06-16 | [`284be59`](https://github.com/obra/superpowers/commit/284be5905ed540d34ce5bcde24728b9b7f413ea0) | Set v6.0.0 release date to 2026-06-16 | upstream-only |
| 2026-06-16 | [`cf32920`](https://github.com/obra/superpowers/commit/cf32920d3a7e231042c72740242cdf97318460fa) | fix: exclude repo metadata from Codex sync (PRI-1168) | upstream-only |
| 2026-06-16 | [`29c0b1b`](https://github.com/obra/superpowers/commit/29c0b1b7db4b8ab488c7ef99bef93068576a60fa) | fix: read Codex plugin version from manifest (PRI-2240) | upstream-only |
| 2026-06-16 | [`a21956e`](https://github.com/obra/superpowers/commit/a21956e48c1324737257c0d9562e5397d1fbed6c) | Release v6.0.1: Codex fixes | upstream-only |
| 2026-06-16 | [`b62616f`](https://github.com/obra/superpowers/commit/b62616fc12f6a007c6fd5118146821d748da0d33) | Release v6.0.2: stop shipping the evals submodule | upstream-only |
| 2026-06-18 | [`207a12b`](https://github.com/obra/superpowers/commit/207a12b20345a391f05ee23e3e87bf7d717c8bbe) | feat(sdd): add sdd-workspace helper for a self-ignoring artifact dir | upstream-only |
| 2026-06-18 | [`93b8444`](https://github.com/obra/superpowers/commit/93b8444b51aeae2e1a8ad9a97124ef6ca528b533) | fix(sdd): write artifacts to working-tree .superpowers/sdd, not .git/ (#1780) | upstream-only |
| 2026-06-18 | [`667b2c4`](https://github.com/obra/superpowers/commit/667b2c4a2ebdece5377cfe1040da4bb4a3744419) | test(sdd): lock in per-worktree workspace isolation (#1780) | upstream-only |
| 2026-06-18 | [`caf14aa`](https://github.com/obra/superpowers/commit/caf14aac6693ed3604439eb67f55becca23ad995) | test(sdd): wire test-sdd-workspace.sh into the runner; note git clean -fdx | upstream-only |
| 2026-06-18 | [`4f9bd31`](https://github.com/obra/superpowers/commit/4f9bd3131ea4ab4f6d60037ac9c89f13bc8b0392) | docs: add v6.0.3 release notes for the SDD .git/ workspace fix | upstream-only |
| 2026-06-18 | [`549dee6`](https://github.com/obra/superpowers/commit/549dee6f6440c790ba2c63ac9b826d9705128cd0) | test(deps): bump ws to ^8.21.0 in brainstorm-server tests | upstream-only |
| 2026-06-18 | [`896224c`](https://github.com/obra/superpowers/commit/896224c4b1879920ab573417e68fd51d2ccc9072) | Release v6.0.3: SDD artifacts move out of the .git/ protected path | upstream-only |
| 2026-06-30 | [`add6a28`](https://github.com/obra/superpowers/commit/add6a283b17c90dba37fe538b02b7242a512d35f) | Add Codex marketplace manifest | upstream-only |
| 2026-06-30 | [`d376057`](https://github.com/obra/superpowers/commit/d3760570298cadccbb82f4540d1064f7914204ca) | Keep Codex hooks manifest in plugin metadata | upstream-only |
| 2026-06-30 | [`879ae59`](https://github.com/obra/superpowers/commit/879ae59c33a430c7e7726adb0e9f1b4366a2ef5f) | fix(codex): stop bootstrap re-firing on resume (match Claude startup\|clear\|compact) | upstream-only |
| 2026-06-30 | [`640ce6c`](https://github.com/obra/superpowers/commit/640ce6c0e9069bed73f5b63e913c92ab80e9717a) | Remove Codex hooks | upstream-only |
| 2026-06-30 | [`711d895`](https://github.com/obra/superpowers/commit/711d895ce736cbcc5fb0c219ea3f49277f17fa8c) | Remove Gemini CLI support | upstream-only |
| 2026-06-30 | [`e7ddc25`](https://github.com/obra/superpowers/commit/e7ddc25e51abfbf256ad02357548b63bc56bc7aa) | Prune per-harness tool-mapping boilerplate | upstream-only |
| 2026-06-30 | [`777cc2f`](https://github.com/obra/superpowers/commit/777cc2fae44673b16b07b82b3ef082c4c77c3ff9) | Compress the using-superpowers bootstrap | upstream-only |
| 2026-06-30 | [`e1753f6`](https://github.com/obra/superpowers/commit/e1753f6e772465feb505cbcb002449fb4df18bb4) | test(codex): assert Codex manifest ships no hooks | upstream-only |
| 2026-06-30 | [`f268f7c`](https://github.com/obra/superpowers/commit/f268f7c953744036f0fa7e9d4b73535c04e57cb8) | Release v6.1.0: leaner per-session bootstrap, Codex marketplace install, Gemini removed | upstream-only |
| 2026-07-02 | [`7d8d3d4`](https://github.com/obra/superpowers/commit/7d8d3d4b06868f1f00834db9764560c7686db466) | fix(codex): suppress SessionStart hook auto-discovery with empty hooks object | upstream-only |
| 2026-07-02 | [`da4125d`](https://github.com/obra/superpowers/commit/da4125d52b80a7049c2881e7263f8b71af2172cd) | Add Codex portal package script | upstream-only |
| 2026-07-02 | [`1a1243b`](https://github.com/obra/superpowers/commit/1a1243b6dd09525518b26fa41d1194f52b8f7de8) | Harden Codex package script checks | upstream-only |
| 2026-07-02 | [`cf12786`](https://github.com/obra/superpowers/commit/cf12786d081a14a9dee89a6f909c3874c46eb32b) | Default Codex portal package to zip | upstream-only |
| 2026-07-02 | [`4572974`](https://github.com/obra/superpowers/commit/4572974c46315b9070bd1c211a1d06a0a4f59842) | Fix Codex plugin category | upstream-only |
| 2026-07-02 | [`28b96af`](https://github.com/obra/superpowers/commit/28b96af905dbb9d5f2b7a2df3030ba860858ef2d) | chore(codex): remove orphaned session-start-codex hook + refresh hook docs | upstream-only |
| 2026-07-02 | [`ec46cf8`](https://github.com/obra/superpowers/commit/ec46cf8277fe15540ec74804011054bdcc078df5) | docs: re-anchor Shape A examples away from Codex | upstream-only |
| 2026-07-02 | [`a50def9`](https://github.com/obra/superpowers/commit/a50def9cefccb47d2e937fc237df980ee09e1fad) | Strip hooks from Codex portal package | upstream-only |
| 2026-07-02 | [`1c330e1`](https://github.com/obra/superpowers/commit/1c330e1b874b93ce77aee57b88c8327cbb228e57) | Preserve hooks in Codex package manifest | upstream-only |
| 2026-07-02 | [`d884ae0`](https://github.com/obra/superpowers/commit/d884ae04edebef577e82ff7c4e143debd0bbec99) | Release v6.1.1: fix Codex SessionStart hook re-registration, add Codex portal packaging | upstream-only |
| 2026-07-23 | [`1d4c8d2`](https://github.com/obra/superpowers/commit/1d4c8d2aafb8fa0de3e5d7df80ff44899fa7e402) | Revert "Remove Gemini CLI support" | upstream-only |
| 2026-07-23 | [`03147d2`](https://github.com/obra/superpowers/commit/03147d23992d0ae80b04fc24af67063607dfac3b) | refactor(skills): fold Integration skill lists into points of use | upstream-only |
| 2026-07-23 | [`af67e03`](https://github.com/obra/superpowers/commit/af67e03f85baace34c5564c3bf934f45e3c2d36d) | refactor(skills): fold systematic-debugging Related-skills block into Phase 4 | upstream-only |
| 2026-07-23 | [`9dff1a9`](https://github.com/obra/superpowers/commit/9dff1a901f120a9d30e59d1658d2a417d863d499) | refactor(skills): stop offering to discard work in finishing-a-development-branch | upstream-only |
| 2026-07-23 | [`bcfe798`](https://github.com/obra/superpowers/commit/bcfe79869a4aeba201cf9300f2a8426647e11787) | refactor(skills): make PR creation forge-agnostic in finishing-a-development-branch | upstream-only |
| 2026-07-23 | [`fbb6dba`](https://github.com/obra/superpowers/commit/fbb6dba450a74154baae931293ecffc8d836c1a3) | refactor(skills): compress finishing-a-development-branch, adopt rationalization table | upstream-only |
| 2026-07-23 | [`0b47219`](https://github.com/obra/superpowers/commit/0b47219ac864352eed51237b81633986f88f3aa6) | fix(skills): capture worktree path before Step 5 changes directory | upstream-only |
| 2026-07-23 | [`e74961c`](https://github.com/obra/superpowers/commit/e74961c110488b52169f0854eea47c8fcee15e23) | refactor(skills): reframe testing-anti-patterns as writing-good-tests | upstream-only |
| 2026-07-23 | [`50025d1`](https://github.com/obra/superpowers/commit/50025d16acd7458e0232850f53a55a2f41e9b626) | fix(skills): broaden writing-good-tests trigger to any test writing | upstream-only |
| 2026-07-23 | [`9d8630d`](https://github.com/obra/superpowers/commit/9d8630d5d933d93b2958d6a0cd9e759d4df1539b) | feat(skills): absorb falsifiability discipline into writing-good-tests | upstream-only |
| 2026-07-23 | [`e8a9748`](https://github.com/obra/superpowers/commit/e8a9748a3fa9ecd1e480ace6cb3ea073ee58d899) | fix(skills): close the change-detector hole in writing-good-tests | upstream-only |
| 2026-07-23 | [`517a9c6`](https://github.com/obra/superpowers/commit/517a9c64191145ed69afbff4b4785c751eb65dbb) | refactor(skills): compress writing-good-tests additions; doc changes earn no tests | upstream-only |
| 2026-07-23 | [`caa1826`](https://github.com/obra/superpowers/commit/caa1826cbadeb88f88c7ad7b3f66178cba01e57d) | experiment: ground-up two-principle rewrite of writing-good-tests | upstream-only |
| 2026-07-23 | [`6dbbbda`](https://github.com/obra/superpowers/commit/6dbbbda3baeff8407f3dddb0cc9e8a9495a273bc) | refactor(skills): drop social proof from dispatching-parallel-agents | upstream-only |
| 2026-07-23 | [`c74782e`](https://github.com/obra/superpowers/commit/c74782ead66b8ded584d9b9cf64dcba95457f320) | refactor(skills): drop social proof from systematic-debugging | upstream-only |
| 2026-07-23 | [`3be5aad`](https://github.com/obra/superpowers/commit/3be5aad3dd2400ef23b15680969f4bcd3b6d7b8b) | refactor(skills): drop persuasion sections from verification-before-completion | upstream-only |
| 2026-07-23 | [`09fc6e0`](https://github.com/obra/superpowers/commit/09fc6e0f3be2a3d74e95c6058408a76972e4571b) | refactor(skills): trim quality claim from executing-plans subagent note | upstream-only |
| 2026-07-23 | [`2173c1c`](https://github.com/obra/superpowers/commit/2173c1c2b48d4a966d6fd010cd0f3404f95d164a) | refactor(skills): drop Advantages section from subagent-driven-development | upstream-only |
| 2026-07-23 | [`cfb6281`](https://github.com/obra/superpowers/commit/cfb6281371ef2d2b7937b22eb475a11a9644ff87) | refactor(skills): trim requesting-code-review, keep review guards as a table | upstream-only |
| 2026-07-23 | [`bc86802`](https://github.com/obra/superpowers/commit/bc868020bbcec32bbaf9d6b51fa0538dba0b487f) | refactor(skills): convert using-git-worktrees guard sections to rationalization table | upstream-only |
| 2026-07-23 | [`05d90ac`](https://github.com/obra/superpowers/commit/05d90ac59248e6716f1a81e79757d850e62f4f7d) | refactor(skills): fold brainstorming Key Principles into points of use | upstream-only |
| 2026-07-23 | [`1e14b23`](https://github.com/obra/superpowers/commit/1e14b2377e37a06f4ac2ab0ea3095d1076db36fd) | refactor(skills): drop Remember recap from writing-plans | upstream-only |
| 2026-07-23 | [`153d618`](https://github.com/obra/superpowers/commit/153d6186c5c35e29ee2be2e4a9ecc1a1e2899bfc) | refactor(skills): drop The Bottom Line recap from writing-skills | upstream-only |
| 2026-07-23 | [`3fb7597`](https://github.com/obra/superpowers/commit/3fb75974186ea7fada621d8ab77b3b02169baf57) | refactor(skills): drop The Bottom Line recap from receiving-code-review | upstream-only |
| 2026-07-23 | [`b9e75dd`](https://github.com/obra/superpowers/commit/b9e75dddec7a384f42ce08532ec17bb1ef5d9459) | refactor(skills): fold TDD Why Order Matters rebuttals into rationalization table | upstream-only |
| 2026-07-23 | [`a80b7b6`](https://github.com/obra/superpowers/commit/a80b7b63865a084f229e71be5239bfc57982401d) | test: realign antigravity + pi mapping assertions with pruned references | upstream-only |
| 2026-07-23 | [`a60dc2f`](https://github.com/obra/superpowers/commit/a60dc2ffe5c5c4b0a833f52cdc8d531f8d09bedc) | test(pi): scope mapping assertions to the table, not whole file | upstream-only |
| 2026-07-23 | [`d238a48`](https://github.com/obra/superpowers/commit/d238a48f5d6b8f51f822fea17d646cfe177747ee) | docs: fix dead references to pruned claude-code-tools.md/copilot-tools.md | upstream-only |
| 2026-07-23 | [`50fbea0`](https://github.com/obra/superpowers/commit/50fbea0488075c42672b7346244250f92c078805) | docs(specs): SDD plan-scoped workspace design | upstream-only |
| 2026-07-23 | [`fe5e9c9`](https://github.com/obra/superpowers/commit/fe5e9c9de931f8008f7da4683a65bf0848ce4482) | docs(plans): SDD plan-scoped workspace implementation plan | upstream-only |
| 2026-07-23 | [`485162e`](https://github.com/obra/superpowers/commit/485162ee00c0e538552549b74b5b3fdb65308463) | docs(plans): fixture v2 — real cited commits, matched task counts | upstream-only |
| 2026-07-23 | [`dd57200`](https://github.com/obra/superpowers/commit/dd57200de1c2d7e208dff93f0cb5f78372ca4200) | docs(plans): re-scope eval per maintainer decision — RED compiled, GREEN measures cost | upstream-only |
| 2026-07-23 | [`40e8665`](https://github.com/obra/superpowers/commit/40e866580dc8f9de76829d3311c58bbb3dae7535) | docs(specs): record eval re-scope — blind adoption did not reproduce, claims narrowed | upstream-only |
| 2026-07-23 | [`256b42f`](https://github.com/obra/superpowers/commit/256b42f454a110102c76403abfebb53b6c5c6ba1) | eval(sdd): RED baseline — 25/25 controllers refuse stale ledgers, at a forensic cost | upstream-only |
| 2026-07-23 | [`6df8ba1`](https://github.com/obra/superpowers/commit/6df8ba145873f72d3307f128745c7aea00f589c4) | feat(sdd): plan-scoped workspace — one .superpowers/sdd/<plan> dir per plan | upstream-only |
| 2026-07-23 | [`b8a2d84`](https://github.com/obra/superpowers/commit/b8a2d84b40a33d7e047f2267ade109a67a2e19c0) | feat(sdd): plan-scoped durable progress — ledger names its plan, workspace dies at plan end | upstream-only |
| 2026-07-23 | [`e782674`](https://github.com/obra/superpowers/commit/e7826745ee250e371fea9acf1fb38a516a3bc39f) | eval(sdd): GREEN results — plan-scoped resolution replaces cross-plan forensics | upstream-only |
| 2026-07-23 | [`2dbbaed`](https://github.com/obra/superpowers/commit/2dbbaed081a5caee0573d992b2c73b586a7d5dc3) | chore(sdd): consistency sweep for plan-scoped workspace signatures | upstream-only |
| 2026-07-23 | [`5151e7a`](https://github.com/obra/superpowers/commit/5151e7aebece23c77545df8af6b9902f9fda7364) | fix(hooks): dispatch the SessionStart hook via Git Bash on Windows | upstream-only |
| 2026-07-23 | [`52f649e`](https://github.com/obra/superpowers/commit/52f649e4ecc4f1e3673ecd3ea7e0be6fd15e0087) | docs(windows): document shell:bash hook dispatch and the PowerShell/CMD fallback hazards | upstream-only |
| 2026-07-23 | [`5d5b656`](https://github.com/obra/superpowers/commit/5d5b6567a804098dca9c09ea1d6bd4dfde6397bf) | fix(codex): make package script and its test portable beyond macOS/bsdtar | upstream-only |
| 2026-07-23 | [`0e13ad8`](https://github.com/obra/superpowers/commit/0e13ad8222c67fe3bb7a2222e996dc34961847d9) | fix(tests): stop the SDD skill test flaking on timing and prose case | upstream-only |
| 2026-07-23 | [`55bbb52`](https://github.com/obra/superpowers/commit/55bbb52c7e0c5df4b459b0c62142ee120bac8c34) | docs(specs): SDD fix-loop redesign design spec | upstream-only |
| 2026-07-23 | [`c6fa27e`](https://github.com/obra/superpowers/commit/c6fa27e3f80adc29020b7bb2bab984f39ce73d19) | docs(plans): SDD fix-loop redesign implementation plan | upstream-only |
| 2026-07-23 | [`87e4050`](https://github.com/obra/superpowers/commit/87e4050daac906590f6002ba90e0c587ebf6a2fe) | feat(sdd): add scoped re-review prompt template | upstream-only |
| 2026-07-23 | [`28882fc`](https://github.com/obra/superpowers/commit/28882fcbc358e7d348da324c3ba458cbe44928bf) | feat(sdd): align templates and codex reference with resume-based fix rounds | upstream-only |
| 2026-07-23 | [`ebdd4ec`](https://github.com/obra/superpowers/commit/ebdd4ec61f2f560bada4f6ded7b0806e62bf33f7) | feat(sdd): lifecycle restructure with resume-based fix loop, five-round breaker, and rationalization table | upstream-only |
| 2026-07-23 | [`a868631`](https://github.com/obra/superpowers/commit/a868631a8a4a942656b7837b60f24c393f86547a) | docs(using-superpowers): drop dangling subagent-support anchor (#2010) | upstream-only |
| 2026-07-23 | [`6015d37`](https://github.com/obra/superpowers/commit/6015d37fe623cf0a7982d6f93fde0c6fef2f92b0) | fix(systematic-debugging): match find -path ./ prefix in find-polluter.sh (#2011) | upstream-only |
| 2026-07-23 | [`c8921b5`](https://github.com/obra/superpowers/commit/c8921b5156562b61af253150a4d1d01a71705be8) | fix(systematic-debugging): find-polluter accepts ./-prefixed patterns and matches top-level tests | upstream-only |
| 2026-07-23 | [`3dcbd5c`](https://github.com/obra/superpowers/commit/3dcbd5c4b48e02263fbf4a3c01e3fe4f81d584d9) | Release v6.2.0: SDD plan-scoped workspace and resume-based fix loop, skills compression sweep, Windows SessionStart fix (#2026) | upstream-only |
| 2026-07-28 | [`44c9b2d`](https://github.com/obra/superpowers/commit/44c9b2d6e889982ac18c27d05a19fefe335194e1) | docs: remove the "We're Hiring" section from the README | upstream-only |
- Are there Windows users, and therefore does the `"shell": "bash"` gap matter?
