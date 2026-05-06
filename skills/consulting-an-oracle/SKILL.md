---
name: superpowers-ruby:consulting-an-oracle
description: Use when stuck after multiple debug attempts and want to escalate to a stronger one-shot model (GPT-5 Pro, Opus, Gemini Pro) — packages a self-contained "oracle prompt" with Ruby/Rails project briefing, verbatim error, what-was-tried, constraints, and just-enough attached files. Triggers include "ask the oracle", "write a letter to GPT-5", "I'm stuck, draft a prompt for another model", "/tmp/letter.md".
---

# Consulting an Oracle

## Overview

When in-session debugging has stalled, package the failed investigation into a single self-contained markdown file that a stronger one-shot model can answer cold. The oracle has zero project knowledge and no memory of prior runs — the prompt must stand alone.

**Core principle:** Just-enough context beats whole-repo dumps. A focused 1500-line prompt outperforms a 30k-line dump every time.

**This skill produces a file. It does not call any model.** Print the path and suggested invocation; let the user run it. This separation is deliberate: keeping prompt-construction decoupled from model-orchestration keeps the skill model-agnostic (works with any oracle the user picks — Codex, Claude, Gemini, paste-into-chat), keeps the artifact re-runnable later, and avoids coupling the skill to credentials, CLI availability, or cost decisions that belong to the user.

**Announce at start:** "I'm using the consulting-an-oracle skill to package this investigation."

## When to Use

- 3+ failed fix attempts on the same symptom in this session
- User says "ask the oracle", "ask GPT-5", "write a letter to an expert", "draft a prompt for another model", "/tmp/letter.md"
- Investigation is consuming context with no convergence
- Before compaction, when the failed investigation should outlive this session as a one-shot prompt

**Don't use when:**
- You haven't actually tried to debug yet → use `superpowers-ruby:systematic-debugging`
- The bug is solved → use `superpowers-ruby:compound`
- Handing off to another Claude session with full plugin/tooling → use `superpowers-ruby:handoff`
- The user wants you to keep trying → keep trying

## Output

**Location:** `tmp/oracle/<YYYY-MM-DD>-<slug>.md` (Rails projects gitignore `tmp/` already).
**Fallback:** `/tmp/oracle-<slug>.md` if `tmp/` isn't writable or this isn't a Rails project.

**Slug:** short kebab-case description of the failing symptom — `zeitwerk-constant-loop`, `n-plus-one-after-cache-add`, `turbo-stream-double-render`. Not the branch name, not the ticket ID.

After writing, print:

```
Oracle prompt: tmp/oracle/2026-05-06-<slug>.md
Suggested invocation:
  codex --model gpt-5-pro --file tmp/oracle/2026-05-06-<slug>.md
  # or paste into chat.openai.com / claude.ai / gemini.google.com
```

## The Process

### Step 1: Detect Project Shape

Run these in parallel and capture output:

```bash
cat .ruby-version 2>/dev/null || cat .tool-versions 2>/dev/null
ruby --version
bundle --version 2>/dev/null
grep -E "^\s*(rails|sinatra|hanami|roda|rspec|minitest|sidekiq|good_job|solid_queue|sorbet|rbs|standard|rubocop)" Gemfile 2>/dev/null
test -f Gemfile.lock && grep -E "^\s+(rails|rack|puma|pg|mysql2|sqlite3|redis) \(" Gemfile.lock | head
test -f config/application.rb && grep -E "config\.(autoload|eager_load|cache_classes|active_job|active_record)" config/application.rb
ls config/initializers/ 2>/dev/null
test -f bin/rails && echo "rails app"
test -d app/javascript && ls app/javascript 2>/dev/null
test -f config/importmap.rb && echo "importmap"
test -f Procfile.dev && cat Procfile.dev
```

Extract: Ruby version, Rails (or other framework) version, DB adapter, test framework, background jobs, asset pipeline, type tooling, linter, Hotwire stack.

### Step 2: Pull the Failure

From recent session context (read recent tool results, do not re-run failing commands unless they're cheap):
- The exact failing command (test, request, rake task)
- Verbatim stack trace, top-to-bottom — do not summarize
- Expected vs actual behavior in one sentence each

### Step 3: Reconstruct What-Was-Tried

Walk recent session history (your own tool calls and edits in this conversation). Produce 3–7 entries, each:

```
- Hypothesis: <one line>
  Action:     <what you changed or ran>
  Outcome:    <what happened, including partial successes>
```

Include partial successes — "this fixed *one* of the failing tests but the other still fails" is high-signal for the oracle. Don't pad: if there were only 2 attempts, write 2.

### Step 4: Pick Attached Files

Start from the failing file and walk **one hop**:
- The failing file itself
- Classes/modules it references (look at `require`, constant references, method calls on collaborators)
- The matching test file
- Any initializer in `config/initializers/` that touches this area
- `db/schema.rb` excerpt (only the relevant tables) if ActiveRecord-related
- Relevant routes excerpt if request-handling

**Hard cap:** ≤8 files, ≤2000 total lines. If you'd exceed it, prefer fewer files with surrounding context over many files with no context.

### Step 5: Redact Secrets

**This step must run before Step 6, not after.** Redacting an already-written file is leak recovery, not prevention — once secrets are on disk, they may be in editor swap files, OS-level backups (Time Machine, Dropbox, iCloud, `tmp` autosync), shell history, or the user's clipboard before you get a chance to scrub them. Redaction operates on the in-memory prompt body and file contents *before* the Write tool persists anything.

Scan the prompt body and every attached file for:

- Files: `.env*`, `master.key`, `credentials.yml.enc`, `*.pem`, `*.key` → **never include, even if asked**
- Patterns: `(?i)(api[_-]?key|secret|token|password|bearer|authorization)\s*[:=]\s*['"][^'"]+['"]`
- Patterns: connection strings with embedded credentials (`postgres://user:pass@...`)
- Patterns: long base64 / hex strings near words like "key", "token", "secret"

Replace with `[REDACTED:<reason>]` and keep enough surrounding context for the oracle to understand the structure. Note redactions in the safety footer.

### Step 6: Write the File

Use the structure in `template.md`. Section order matters — role and desired output go first because oracles weight the opening of long prompts most heavily.

### Step 7: Report

Print the file path, line count, and suggested invocation. Do not call any model. Do not open the file in an editor.

## Ruby/Rails-Specific Suspect List

Always include this section in the oracle prompt — these are the implicit-context items that bite Ruby projects and that an oracle cannot infer:

- **Autoloading:** Zeitwerk vs Classic? Is the failing constant in `app/`, `lib/`, or an engine? Is `lib/` in autoload paths? Eager-load mode in this environment?
- **Frozen string literals:** Magic comment present in the failing file?
- **Thread safety:** Puma worker/thread count, ActiveRecord connection pool size, any `Thread.current` usage in the call stack
- **Initializer order:** If config-related, what loads before this code? Custom initializers that monkey-patch?
- **Gem version drift:** `git log -p Gemfile.lock` for recently bumped gems on the failing path
- **Monkey patches:** Anything in `config/initializers/`, `lib/core_ext/`, or `app/lib/` that reopens the failing class?
- **ActiveSupport gotchas:** `present?`/`blank?`/`try` collisions, `delegate` chains, `with_options` blocks
- **Rails environment:** Is the bug environment-specific (dev vs test vs prod)? `config/environments/*.rb` differences on the relevant flag?
- **Background jobs:** Is the failing code on a sync path or a job path? Adapter (Sidekiq/Solid Queue/GoodJob)?
- **Schema vs model:** Recent migrations not yet reflected in `db/schema.rb`?

Include only the items that *might* be relevant. Don't pad.

## Anti-patterns

- ❌ Dumping the whole repo "to be safe" — destroys signal
- ❌ Summarizing the stack trace — oracles need the verbatim text
- ❌ Including `.env` "with secrets redacted by hand" — use the redaction step, never trust manual redaction of entire files
- ❌ Writing in second person to the user ("you should check...") — write in the voice of someone briefing a peer
- ❌ Asking the oracle an open-ended question ("what's wrong?") — specify the desired output format
- ❌ Including narrative about the session ("we first tried X, then Joe suggested Y") — the oracle doesn't know Joe; structure as hypothesis/action/outcome

## Re-runnability

Oracles are one-shot — the model has no memory of prior runs. Write the prompt so that re-running it later (with the same `--file` argument) reproduces the same context. That means:

- Absolute file paths, not "the file we were just looking at"
- Git SHA at the top so the oracle knows the snapshot
- No references to "earlier in the session" or "as I mentioned"

## Quick Reference

| Step | Action |
|------|--------|
| 1 | Detect Ruby/Rails project shape |
| 2 | Pull verbatim failure (command, stack trace, expected vs actual) |
| 3 | Reconstruct hypothesis → action → outcome from session |
| 4 | Pick ≤8 files / ≤2000 lines, one hop from failing file |
| 5 | Redact secrets aggressively |
| 6 | Write `tmp/oracle/<date>-<slug>.md` using `template.md` |
| 7 | Print path + suggested invocation; do not call any model |

See `template.md` for the exact section layout.
