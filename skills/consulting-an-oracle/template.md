# Oracle Prompt Template

Copy this structure verbatim into `tmp/oracle/<date>-<slug>.md`. Section order is intentional — oracles weight the top of long prompts most.

---

# Oracle Consultation: <one-line problem statement>

> Snapshot: `<git rev-parse --short HEAD>` on branch `<git branch --show-current>` at `<UTC timestamp>`

## Your Role and Desired Output

You are a senior Ruby/Rails engineer reviewing this brief cold. You have no prior context and no memory of earlier consultations. Please return:

1. **Ranked hypotheses** — most likely root cause first, with the reasoning that distinguishes it from the alternatives
2. **Patch plan** — specific files and changes, including any new tests that would prove the fix
3. **Risky assumptions** — things you're inferring from the brief that, if wrong, would invalidate your answer
4. (Optional) **Three options with tradeoffs** if the fix is a judgment call

Be direct. If the brief is missing something critical, say what and why.

## Project Briefing

- **Language/Framework:** Ruby <X.Y.Z>, Rails <X.Y.Z> (or: Sinatra/Hanami/Roda/none)
- **Database:** <postgres/mysql/sqlite> via <adapter gem>
- **Test framework:** <Minitest/RSpec>, run with `<command>`
- **Background jobs:** <Sidekiq/Solid Queue/GoodJob/none>, queue adapter = `<value>`
- **Asset pipeline:** <Propshaft/Sprockets> + <importmap/jsbundling/none>
- **JS framework:** <Hotwire (Turbo X.Y, Stimulus X.Y)/React/none>
- **Type tooling:** <Sorbet/RBS+Steep/none>
- **Linter:** <RuboCop/StandardRB/none>
- **Deploy target:** <Heroku/Fly/Kamal/AWS/unknown>
- **Ruby version manager:** <rbenv/asdf/mise/chruby>

## Where Things Live

- Custom autoload paths beyond Rails defaults: `app/services/`, `app/queries/`, `lib/<...>` (or: standard layout)
- Relevant entrypoints for this bug: `<file>`, `<file>`
- Relevant initializers: `config/initializers/<file>.rb` (or: none)
- Engines / mounted apps that touch this code path: <list or "none">

## The Question

**One-line question:** <what do you want the oracle to answer>

**Failing command:**
```
<exact command, e.g. bin/rails test test/models/user_test.rb -n test_creates_audit_log>
```

**Verbatim error / stack trace:**
```
<paste full output, do not summarize>
```

**Expected behavior:** <one sentence>
**Actual behavior:** <one sentence>

**Reproduction steps** (if not just running the command):
1. <step>
2. <step>
3. <step>

## What I Already Tried

- **Hypothesis:** <one line>
  **Action:** <change made or command run>
  **Outcome:** <what happened, including partial wins>

- **Hypothesis:** <one line>
  **Action:** <...>
  **Outcome:** <...>

(Repeat for each attempt — typically 3–7. Include partial successes; they're high-signal.)

## Constraints

- <e.g. "Public API of `User#audit!` must not change — it's called from a sealed gem">
- <e.g. "Must work on Ruby 3.3 and 3.4">
- <e.g. "No new gems">
- <e.g. "P95 of this request path must stay under 200ms">
- <e.g. "Cannot modify `db/schema.rb` outside a migration">

## Ruby/Rails-Specific Context

(Include only items that might be relevant — don't pad.)

- **Autoloading:** Zeitwerk, eager_load = <true/false> in this environment. Failing constant is in `<app/lib/...>`.
- **Frozen string literals:** `# frozen_string_literal: true` <present/absent> in failing file.
- **Thread safety:** Puma `<workers>` workers × `<threads>` threads. AR pool size = `<n>`. Failing code path <does/does not> use `Thread.current`.
- **Initializer order:** `<initializer>` runs before this code and does `<thing>`.
- **Recent Gemfile.lock changes:** `<gem>` bumped from `<old>` to `<new>` in commit `<sha>`.
- **Monkey patches:** `<file>` reopens `<class>` to add `<method>`.
- **Environment:** Bug occurs in `<dev/test/prod>`. The relevant config differs: `<flag>` is `<value>` here vs `<value>` elsewhere.
- **Job vs sync:** Failing code runs on `<sync request / Sidekiq job / Solid Queue job>`.
- **Schema drift:** `db/schema.rb` <is/is not> in sync with `db/migrate/`.

## Attached Files

Files included below: `<list of paths>` (total: <N> lines)

### `<path/to/failing_file.rb>`
```ruby
<full contents or relevant excerpt with line numbers>
```

### `<path/to/collaborator.rb>`
```ruby
<...>
```

### `<path/to/test.rb>`
```ruby
<...>
```

### `db/schema.rb` (relevant excerpt)
```ruby
<only the tables involved>
```

### `config/initializers/<relevant>.rb`
```ruby
<...>
```

## Safety / Redactions

The following were redacted from this brief and the attached files:

- `<count>` instances of API keys / tokens / passwords (replaced with `[REDACTED:credential]`)
- `<count>` connection strings with embedded credentials (replaced with `[REDACTED:db-url]`)
- Excluded entirely: `.env`, `config/master.key`, `config/credentials.yml.enc`

If the answer depends on the redacted values, please flag what you'd need to know in non-secret form (e.g. "is the API key the staging or production format?") rather than asking for the value itself.

---

*End of brief. The oracle has no memory of prior runs — re-running this prompt with the same file produces the same context.*
