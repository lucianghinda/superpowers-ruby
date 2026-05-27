# Ruby 4.0 breaking-change inventory

Canonical reference for the `ruby-upgrade` skill. Each entry lists the change,
how to detect exposure in a codebase, the risk level, and the remediation.

> Verified against the upstream Ruby 4.0.0 release announcement
> (https://www.ruby-lang.org/en/news/2025/12/25/ruby-4-0-0-released/) and the
> `ruby/ruby` `gems/bundled_gems` manifest
> (https://github.com/ruby/ruby/blob/master/gems/bundled_gems). When a project
> pins a specific patch (e.g. 4.0.5), check the patch-level changelog too.

## change-01 — `Net::HTTP` no longer sets an implicit Content-Type

**What:** POST/PUT/PATCH requests built without an explicit `Content-Type`
header no longer default to `application/x-www-form-urlencoded`. Servers that
relied on the implicit header may now reject requests with `400`/`415`.

**Detect:** `rg "Net::HTTP::(Post|Put|Patch)"`, `rg "Net::HTTP.post_form"`. Also
audit wrapping HTTP clients in the lockfile: Faraday, HTTParty, RestClient,
Excon, http.rb, Typhoeus.

**Risk:** High for service-to-service API integrations.

**Action:** Set `request["Content-Type"]` (or the client's equivalent) explicitly
on every mutating request.

## change-02 — CGI escape/unescape split from CGI session classes

**What:** The escaping helpers stay available via `require "cgi/escape"`
(`CGI.escape`, `CGI.unescape`, `CGI.escapeHTML`, `CGI.unescapeHTML`,
`CGI.escapeURIComponent`, `CGI.unescapeURIComponent`, `CGI.escapeElement`,
`CGI.unescapeElement`). The higher-level pieces — `CGI.parse`, `CGI::Cookie`,
`CGI::Session`, `CGI.new` — are removed from default and need the `cgi` gem.

**Detect:** `rg "CGI\.(parse|new)"`, `rg "CGI::(Cookie|Session)"` (need gem) vs
`rg "CGI\.(escape|unescape)"` (still fine).

**Risk:** Medium.

**Action:** Add `gem "cgi"` to the Gemfile if any of the removed APIs are used.

## change-03 — default gems promoted to bundled gems

**What:** Ten stdlib libraries move from *default* to *bundled* gems. They still
ship with Ruby, but a `require` at runtime now fails under Bundler unless the
gem is declared in the Gemfile (works at the bare REPL — `bundle exec` is where
it bites). Full list per
[`ruby/ruby gems/bundled_gems`](https://github.com/ruby/ruby/blob/master/gems/bundled_gems)
and the Ruby 4.0.0 release NEWS:

| Gem | Version at 4.0.0 |
|-----|------------------|
| `ostruct` | 0.6.3 |
| `pstore` | 0.2.0 |
| `benchmark` | 0.5.0 |
| `logger` | 1.7.0 |
| `rdoc` | 7.0.2 |
| `win32ole` | 1.9.2 *(Windows only)* |
| `irb` | 1.16.0 |
| `reline` | 0.6.3 |
| `readline` | 0.0.4 |
| `fiddle` | 1.1.8 |

**Detect:** `rg 'require "(ostruct|pstore|benchmark|logger|rdoc|win32ole|irb|reline|readline|fiddle)"'`.
Then check whether each match is already resolved in Gemfile/Gemfile.lock
(Rails 7.1+ pins several of these transitively).

**Risk:** Low when on Rails 7.1+; medium for plain Ruby apps. Windows CI legs
should specifically check `win32ole`.

**Action:** Add a `gem "<name>"` line ONLY for libraries the app `require`s
directly and that are not already resolved transitively. Adding a duplicate
that fights the lock is its own bug.

## change-04 — `Set` promoted to core, `SortedSet` removed

**What:** `Set` is promoted from stdlib to a core class (no `require "set"`
needed). Separately, `set/sorted_set.rb` is removed — `SortedSet` now requires
the standalone `sorted_set` gem.

**Detect:** `rg "SortedSet"` (usually zero hits); `rg 'require "set"'` (now
redundant, harmless).

**Risk:** Low.

**Action:** Use `Set` + explicit sorting, or add the `sorted_set` gem.

## change-05 — `Set#inspect` output format changed

**What:** `Set#inspect` now renders as `Set[1, 2, 3]` instead of the old
`#<Set: {1, 2, 3}>`. Any test asserting on the old literal breaks.

**Detect:** `rg "#<Set:" spec/ test/`.

**Risk:** Medium for snapshot/inline-snapshot test suites.

**Action:** Update assertions to the `Set[...]` form, or assert on contents
instead of the inspect string.

## change-06 — `Kernel#open` pipe form removed

**What:** The `open("|command")` pipe-subprocess form is removed; use
`IO.popen` explicitly.

**Detect:** `rg 'open\(["'\'']\|'`, `rg 'File.open\(["'\'']\|'`, `rg 'IO.read\(["'\'']\|'`.

**Risk:** Low (rare), but a security-relevant pattern when present.

**Action:** Rewrite with `IO.popen`.

## change-07 — `Process::Status#&` and `#>>` removed

**What:** Bitwise operations on `Process::Status` are removed.

**Detect:** `rg "Process::Status"` then inspect for `&`/`>>` usage.

**Risk:** Low (usually zero).

**Action:** Use the dedicated predicate/accessor methods (`exitstatus`,
`signaled?`, etc.).

## change-08 — OpenSSL 4 default

**What:** Ruby 4.0 ships with a newer OpenSSL binding by default. Gems pinning
an older `openssl` may conflict.

**Detect:** Look for `openssl` pins below `4.0` in Gemfile/Gemfile.lock; also
review crypto-adjacent gems: jwt, devise, doorkeeper, ruby-saml, omniauth.

**Risk:** Low, but blocks `bundle` resolution when a hard pin exists.

**Action:** Relax/raise the pin; re-resolve.

## change-09 — native-extension recompile required

**What:** A Ruby major bump invalidates compiled C extensions. Cached
`vendor/bundle` directories (common in Docker layers) hold extensions built
against the old ABI and will crash on `require`.

**Detect:** No static signal — surfaces as a crash on `require` of a C-extension
gem (nokogiri, pg, grpc, ffi, bcrypt, msgpack) after `bundle install` "succeeds".

**Risk:** Medium in Dockerized/CI environments.

**Action:** `rm -rf vendor/bundle && bundle install` (and bust the relevant
Docker layer cache).

## change-10 — error backtrace / `ArgumentError` receiver format changed

**What:** Backtrace and some exception message formats changed. Error-grouping
in monitoring tools (Sentry, Bugsnag, Rollbar, Honeybadger, Datadog APM) may
split known issues into new fingerprints.

**Detect:** No static signal — review error-tracker init paths and any code that
parses backtrace strings.

**Risk:** Medium for observability, not for app correctness.

**Action:** Expect fingerprint churn for ~24h post-deploy; coordinate with
whoever owns alerting so the noise is expected, not paged.

## change-11 — `Ractor` API removals (`Ractor::Port`)

**What:** With the addition of `Ractor::Port`, several methods are removed:
`Ractor.yield`, `Ractor#take`, `Ractor#close_incoming`, `Ractor#close_outgoing`.

**Detect:** `rg "Ractor\.(yield|new)"`, `rg "\.(take|close_incoming|close_outgoing)\b"`
near Ractor usage.

**Risk:** Low unless the app actually uses Ractors (breaking if it does).

**Action:** Migrate the affected message-passing to `Ractor::Port`.

## change-12 — chilled / frozen string literals

**What:** Ruby continues tightening string-literal mutability ("chilled
strings"); files without the `# frozen_string_literal: true` magic comment can
emit new warnings, and in-place mutation of literals is increasingly unsafe.

**Detect:** Count `.rb` files with vs without the magic comment.

**Risk:** Low (warnings), but worth a pass.

**Action:** Add the magic comment; fix any literal mutation it surfaces.

## change-13 — stale URI escaping APIs

**What:** `URI.escape` / `URI.unescape` / `URI.encode` (deprecated since 2.7)
remain a liability and should be migrated even though 4.0 does not remove them.

**Detect:** `rg "URI\.(escape|unescape|encode)\b"`.

**Risk:** Low.

**Action:** Replace with `CGI.escape` / `URI::DEFAULT_PARSER.escape` /
`Addressable::URI` as appropriate.

## change-14 — JIT guidance (ZJIT experimental, RJIT removed)

**What:** ZJIT is introduced as an experimental method-based JIT (its build
requires Rust 1.85.0+). RJIT is removed (moved to an external repo). YJIT
remains the production-safe JIT.

**Action:** Do NOT enable `--zjit` in production on 4.0.x — keep YJIT. If a
Docker/CI image builds Ruby from source with ZJIT, ensure Rust ≥ 1.85.0.

## Quick reference

| # | Change | Risk | Primary detection |
|---|--------|------|-------------------|
| 01 | `Net::HTTP` implicit Content-Type removed | High | grep `Net::HTTP::(Post\|Put\|Patch)` |
| 02 | `CGI.parse`/`CGI::Cookie`/`CGI::Session` removed | Medium | grep `CGI.parse`; add `gem "cgi"` |
| 03 | default gems demoted | Low–Med | grep `require "ostruct"` etc. |
| 05 | `Set#inspect` format | Medium | grep `#<Set:` in tests |
| 09 | native-extension recompile | Medium | crash on `require`; clear `vendor/bundle` |
| 10 | backtrace/fingerprint drift | Medium | monitor post-deploy |
| 08 | OpenSSL 4 default | Low | grep `openssl.*< 4` in lock |
