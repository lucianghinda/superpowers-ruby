---
name: ruby-upgrade
description: Use when upgrading the Ruby interpreter version of a Bundler/Rails app — especially "upgrade to Ruby 4", "bump Ruby to 4.0", "audit Ruby 4 compatibility", "what breaks on Ruby 4", or a specific target like "Ruby 4.0.5". Triggers on Ruby-major risk symptoms: CGI.parse/CGI::Cookie removal, Net::HTTP implicit Content-Type dropped, demoted default gems (ostruct/logger/benchmark/irb), SortedSet, Set#inspect changes, native-extension recompile crashes, openssl 4 pins, and error-tracker fingerprint drift. Also fires on ".ruby-version bump" and "ruby major upgrade". For Rails framework version bumps (6.x/7.x/8.x, config.load_defaults) use the rails-upgrade skill instead.
---

# Ruby Upgrade

## Overview

This skill upgrades a Ruby application from one major/minor Ruby version to
another — currently targeting the **Ruby 3.x → 4.0.x** jump. It runs a
breaking-change risk audit against the codebase, writes a stakeholder-ready
analysis, applies the mechanical toolchain edits (`.ruby-version`, Dockerfile,
CI, RuboCop `TargetRubyVersion`, Gemfile pins), and verifies via `bundle`,
RuboCop, type checks, and the test suite.

**This is the Ruby-interpreter upgrade.** For *Rails framework* version bumps
(6.x → 7.x → 8.x, `config.load_defaults`, railsdiff), use the
`superpowers-ruby:rails-upgrade` skill instead. They are often done together —
run the Rails upgrade's Ruby-compatibility table first to confirm the target
Ruby is supported by the current Rails version.

**Announce at start:** "I'm using the ruby-upgrade skill to plan this Ruby upgrade."

**Breaking-change inventory:** `references/ruby-4-0-changes.md` (bundled with
this skill). It is the source of truth for detection patterns and remediations.

## Modes

The user may ask for one of:

- **audit-only** — stop after writing the analysis report (Phases 0–3).
- **full** (default) — audit, then apply mechanical updates, then verify.

If the target patch isn't specified, default to the latest stable in the target
line and say which you picked.

## Phase 0: Verify repo + anchor target

Confirm this is a Ruby/Rails repo before doing anything:

```bash
git rev-parse --show-toplevel
test -f Gemfile && test -f Gemfile.lock
```

Bail if `Gemfile`/`Gemfile.lock` are missing — this skill operates on a Bundler
project. Read `references/ruby-4-0-changes.md` now and keep it open as you audit.

## Phase 1: Capture current toolchain state

Read in one parallel batch, recording each into a "Current state" table:

- `.ruby-version` (current pin)
- `Gemfile` (note any `ruby "..."` / `ruby file:` directive)
- `Gemfile.lock` (`RUBY VERSION`, `BUNDLED WITH`, and key versions: rails,
  sorbet/tapioca if present, openssl, logger, ostruct, benchmark, irb, reline,
  pry, debug, nokogiri, pg, grpc, ffi, bcrypt, msgpack)
- `Dockerfile` / `*.Dockerfile` (the Ruby base-image line)
- CI config: any of `.github/workflows/*.yml`, `.gitlab-ci.yml`,
  `.gitlab/ci/**/*.yml`, `.circleci/config.yml` mentioning a Ruby version
- `.rubocop.yml` (`AllCops: TargetRubyVersion`)
- `sorbet/config` (only if the project uses Sorbet)

## Phase 2: Risk inventory — parallel grep sweep

Dispatch ONE `Agent` subagent (`subagent_type: Explore`) to sweep the codebase
for every change in `references/ruby-4-0-changes.md`. Hand it that file and ask
for **counts + up to 5 `file:line` examples per change-NN entry**. Cover all
entries (change-01 … change-14), and additionally list any HTTP-client gems
from the lockfile that wrap `Net::HTTP`.

Wait for the structured findings report before proceeding.

## Phase 3: Write the analysis report

Write to a project-relative folder so it works in any repo:

```
docs/ruby-upgrade/<YYYY-MM-DD>/analysis.md
```
and if docs folder is not present write to: 

```
tmp/ruby-upgrade/<YYYY-MM-DD>/analysis.md
```
(Use `date +%Y-%m-%d`. If the project already has a conventional analysis/report
location, prefer that and say so.)

Sections:

1. **TL;DR** — verdict (LOW / MEDIUM / HIGH risk), estimated effort, top 3 blockers.
2. **Current state** — the Phase 1 table.
3. **Risk matrix** — one row per `references/ruby-4-0-changes.md` entry:
   `# | change | exposure (counts + file:line) | risk | action`, each linking
   back to the inventory anchor (e.g. `(./../../skills/ruby-upgrade/references/ruby-4-0-changes.md#change-01)` or by change number).
4. **Phased checklist** — pre-filled boxes for Phase 4.
5. **Surprises** — repo-specific findings (vendored gems, monkey-patches in
   `config/initializers/`, lock already on a newer Bundler, etc.).
6. **Open questions for the team** — type-checker (Sorbet/Steep) Ruby-4 support,
   internal Docker-registry mirroring of the target image, monitoring owner for
   fingerprint drift, gems known to lag Ruby majors (e.g. grpc).

If the user asked for **audit-only**, STOP HERE and print the report path.

## Phase 4: Apply mechanical toolchain updates

Branch hygiene first: if the current branch doesn't already encode this work,
suggest a name like `upgrade-ruby-4-0-5` (prefix with the user's ticket id if
they gave one).

Make each edit **only if the file actually pinned the old version** — never
invent files:

- [ ] `.ruby-version`: write the target (e.g. `4.0.5\n`).
- [ ] Dockerfile(s): change `FROM ...ruby:3.X.X` → `ruby:<target>`. Preserve any
      private-registry prefix on the image (don't rewrite the registry host).
- [ ] CI YAML: bump every literal Ruby version string across all CI files found
      in Phase 1.
- [ ] `.rubocop.yml`: set `AllCops: TargetRubyVersion: <major.minor>`.
- [ ] `Gemfile`: add `gem "cgi"` if any removed CGI API is used (change-02).
      Add `gem "ostruct"` / other demoted gems ONLY if app code `require`s them
      directly and they aren't already resolved (change-03).

Then re-resolve:

```bash
bundle update --ruby
```

Capture the resolution diff. If it fails on a specific gem (commonly grpc, a
Sorbet package, or a hard pre-Ruby-4 pin), STOP applying and record the failing
gem under a "Blockers" section in the report.

## Phase 5: Verify

Run the relevant checks (in parallel where possible):


1. Rubocop
```bash
bundle exec rubocop         # changed files or full repo
```

2. Full test suite:

If the project uses RSpec execute: 
```
bundle exec rspec --fail-fast 
```
else execute: 
```
bundle exec rails test
```
3. If the project is using sorbet: 
```
bundle exec srb tc          # only if sorbet/config exists
bundle exec tapioca gem     # only if the project uses Tapioca — regenerate RBIs
```

On failure: append a "Verification failures" section with the output, then
either fix-forward the obvious cases (RBI staleness, safe RuboCop autocorrects)
or stop and surface to the user. Do not claim success without showing passing
output — see `superpowers-ruby:verification-before-completion`.

Native-extension hint: if `bundle install` succeeded but tests crash on
`require` of a C-extension gem, a cached `vendor/bundle` was built against the
old ABI — `rm -rf vendor/bundle && bundle install` (change-09).

## Phase 6: Post-merge watch (recommend, don't auto-run)

Suggest 24-hour monitoring on whatever error tracker the project uses for:

- new `ArgumentError`/backtrace fingerprints (change-10),
- a spike in `Net::HTTP` `400`/`415` responses from internal clients (change-01),
- new parse errors in any log scrapers that read Ruby internal frames.

## Hard rules

- **Never bump `.ruby-version` without bumping every Dockerfile/CI image in the
  same commit.** Drift between them is the most common deploy-time failure for a
  Ruby-major upgrade.
- **Never auto-add `gem "ostruct"`** (or other demoted gems) unless app code
  directly `require`s them. Rails 7.1+ pins several transitively; a duplicate
  fights the lock.
- **Never enable `--zjit` in production on 4.0.x** — experimental. Keep YJIT.
- **Do not skip the Phase 2 grep sweep.** "Just bump the version and run tests"
  misses `CGI.parse`, openssl pins, and monitoring fingerprint drift — none of
  which the test suite catches.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Editing files that never pinned the old version | Only edit files Phase 1 found pinning it |
| Rewriting a private registry host on the Docker image | Keep the prefix; change only the tag |
| Adding `gem "cgi"`/`"ostruct"` blindly | Add only when the removed/demoted API is actually used |
| Declaring "tests pass" without output | Show the passing run (verification-before-completion) |
| Confusing this with a Rails upgrade | Rails framework bump → `superpowers-ruby:rails-upgrade` |
