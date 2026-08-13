# load_defaults Guide

## What is load_defaults?

`config.load_defaults(version)` in `config/application.rb` controls which new Rails framework defaults are active. When you upgrade Rails, the gem version changes but the defaults version doesn't — meaning you can safely test new defaults incrementally rather than all at once.

```ruby
# config/application.rb
module MyApp
  class Application < Rails::Application
    config.load_defaults 7.1  # This controls defaults, not the gem version
  end
end
```

## load_defaults Values and Their Changes

### load_defaults 5.2

- `config.active_record.cache_versioning` = true (cache keys include version stamp)
- `config.action_dispatch.use_authenticated_cookie_encryption` = true
- `config.active_support.use_authenticated_message_encryption` = true
- `config.active_support.use_sha1_digests` = true
- `config.action_controller.default_protect_from_forgery` = true

Risk: LOW — mostly security improvements

### load_defaults 6.0

- `config.autoloader` = :zeitwerk (major change — file naming must match constants)
- `config.action_view.default_enforce_utf8` = false
- `config.action_dispatch.use_cookies_with_metadata` = true
- `config.action_mailer.delivery_job` = ActionMailer::MailDeliveryJob

Risk: HIGH for autoloader (Zeitwerk naming), LOW for rest

### load_defaults 6.1

- `config.active_record.has_many_inversing` = true (bidirectional associations auto-set inverse)
- `config.active_job.retry_jitter` = 0.15 (adds jitter to retries)
- `config.action_dispatch.cookies_same_site_protection` = :lax
- `config.active_record.legacy_connection_handling` = false

Risk: MEDIUM — has_many_inversing can change association behavior

### load_defaults 7.0

- `config.action_controller.raise_on_open_redirects` = true (security — prevents open redirects)
- `config.action_view.button_to_generates_button_tag` = true
- `config.action_mailer.smtp_timeout` = 5
- `config.active_support.executor_around_test_case` = true
- `config.action_controller.wrap_parameters_by_default` = false (API breaking for some apps)

Risk: MEDIUM — raise_on_open_redirects may break redirect_to calls with user-provided URLs

### load_defaults 7.1

- `config.active_record.query_log_tags_format` = :sqlcommenter
- `config.active_record.cache_query_log_tags` = true
- `config.active_support.message_serializer` = :json_allow_marshal
- `config.active_support.cache_format_version` = 7.1
- `config.action_dispatch.default_headers` updated (security headers)
- `config.action_controller.allow_deprecated_parameters_hash_equality` = false

Risk: MEDIUM — cache format change requires coordinated deploy; message serializer change affects cookies/sessions

### load_defaults 7.2

- `config.active_record.raise_on_assign_to_attr_readonly` = true
- `config.active_record.belongs_to_required_validates_foreign_key` = false
- `config.active_model.i18n_customize_full_message` = true
- `config.active_support.to_time_preserves_timezone` = :zone

Risk: LOW-MEDIUM

### load_defaults 8.0

- `Regexp.timeout` = 1 (caps regex execution at 1 second — mitigates ReDoS)
- `config.action_dispatch.strict_freshness` = true (`ETag` takes precedence over `Last-Modified` per RFC 7232)

Risk: LOW-MEDIUM — `Regexp.timeout` can raise `Regexp::TimeoutError` on genuinely slow regexes (large input, catastrophic backtracking). That is the point, but it surfaces as a new exception class in production.

Note: the Solid Cache / Solid Queue / Solid Cable adoption in Rails 8.0 is a **generator**
change, not a `load_defaults` change. Existing apps are not switched by bumping
`load_defaults`; see `references/breaking-changes.md` for the 7.2 → 8.0 migration.

### load_defaults 8.1

- `config.active_record.raise_on_missing_required_finder_order_columns` = true — `#first`/`#last`/etc. raise `ActiveRecord::MissingRequiredOrderError` on an unordered relation whose model has no order columns
- `config.action_controller.action_on_path_relative_redirect` = :raise — `redirect_to "example.com"` raises `UnsafeRedirectError`
- `config.action_controller.escape_json_responses` = false — the JSON renderer stops escaping HTML entities and line separators
- `config.active_support.escape_js_separators_in_json` = false — U+2028/U+2029 no longer escaped (valid in JS string literals since ECMAScript 2019)
- `config.action_view.render_tracker` = :ruby — template dependency tracking uses a real Ruby parser instead of regex scanning
- `config.action_view.remove_hidden_field_autocomplete` = true — hidden fields from `form_tag`, `token_tag`, `method_tag`, and `button_to` drop `autocomplete="off"`
- `config.yjit` = `!Rails.env.local?` — YJIT now enabled only outside development and test (was unconditionally `true` from 7.2)

Risk: HIGH — this is the heaviest `load_defaults` bump in the 8.x line. Enable
`raise_on_missing_required_finder_order_columns` **on its own** and run the full suite; it
typically surfaces as a wave of test failures rather than a single error.

### load_defaults 8.2 (UNRELEASED)

Rails 8.2 is `8.2.0.alpha` on `main`. Verify against `main` before relying on this.

- `config.action_controller.forgery_protection_verification_strategy` = :header_only — CSRF verified via the `Sec-Fetch-Site` header with **no** authenticity-token fallback
- `config.action_controller.default_protect_from_forgery_with` = :exception — was effectively `:null_session`
- `config.action_dispatch.strict_accept_header` = true — `Accept: application/json, */*` returns JSON instead of defaulting to HTML
- `config.action_dispatch.default_headers` — `X-XSS-Protection` removed (browsers dropped support years ago)
- `config.active_job.enqueue_after_transaction_commit` = true — restored as a global boolean after being removed in 8.1
- `config.active_record.postgresql_adapter_decode_bytea` = true and `postgresql_adapter_decode_money` = true — manual queries return binary Strings and BigDecimals rather than UTF-8 Strings
- `config.active_storage.analyze` = :immediately — attachment metadata extracted before validation, so `width`/`height`/`duration` are available to validators
- `config.action_controller.rescue_from_event_backtrace` = :array — full backtrace in the `rescue_from_handled.action_controller` payload
- `ActiveSupport.raise_on_invalid_time_zone_parse` = true — `TimeZone#parse("foobar")` raises `ArgumentError` instead of returning `nil`

Risk: HIGH — `forgery_protection_verification_strategy: :header_only` and
`strict_accept_header` can both break real clients.

## Risk Tiers

### Tier 1 — Enable safely, minimal risk

- `action_dispatch.use_authenticated_cookie_encryption` (5.2)
- `active_support.use_sha1_digests` (5.2)
- `action_mailer.smtp_timeout` (7.0)
- `active_record.cache_query_log_tags` (7.1)
- `active_model.i18n_customize_full_message` (7.2)
- `action_dispatch.strict_freshness` (8.0)
- `action_view.render_tracker: :ruby` (8.1)
- `action_controller.rescue_from_event_backtrace: :array` (8.2)

### Tier 2 — Enable with testing, may affect behavior

- `active_record.has_many_inversing` (6.1) — test association behavior
- `action_controller.raise_on_open_redirects` (7.0) — grep for redirect_to with dynamic URLs
- `active_support.cache_format_version` (7.1) — coordinate across all servers
- `active_record.belongs_to_required_validates_foreign_key` (7.2)
- `Regexp.timeout: 1` (8.0) — raises `Regexp::TimeoutError` on slow regexes; audit user-input-driven patterns
- `action_view.remove_hidden_field_autocomplete` (8.1) — breaks HTML snapshot assertions
- `active_support.escape_js_separators_in_json` (8.1) — safe in modern browsers
- `active_storage.analyze: :immediately` (8.2) — moves metadata extraction before validation; changes timing for large uploads
- `active_record.postgresql_adapter_decode_bytea` / `decode_money` (8.2) — only affects raw `select_value`-style queries
- `ActiveSupport.raise_on_invalid_time_zone_parse` (8.2) — surfaces user-input parsing that silently returned `nil`

### Tier 3 — Enable carefully, high impact

- `autoloader: :zeitwerk` (6.0) — requires Zeitwerk file naming compliance
- `active_support.message_serializer: :json_allow_marshal` (7.1) — affects cookies/sessions
- `action_controller.wrap_parameters_by_default: false` (7.0) — may break API parameter handling
- `active_record.raise_on_missing_required_finder_order_columns` (8.1) — **the biggest one in 8.x.** Enable alone; expect a wave of test failures from `.first`/`.last` on unordered relations
- `action_controller.action_on_path_relative_redirect: :raise` (8.1) — stage via `:log` or `:notify` and watch logs before flipping
- `action_controller.escape_json_responses: false` (8.1) — unsafe if rendered JSON is interpolated into an HTML `<script>` block
- `action_controller.forgery_protection_verification_strategy: :header_only` (8.2) — no token fallback; old browsers and non-browser clients are rejected. Run `:header_or_legacy_token` first and watch the fallback logs
- `action_controller.default_protect_from_forgery_with: :exception` (8.2) — API endpoints silently relying on `:null_session` start raising
- `action_dispatch.strict_accept_header` (8.2) — can flip the response format of existing endpoints for clients sending `*/*`

## How to Transition load_defaults

### The safe approach

1. After upgrading to Rails X.Y, update Gemfile: `gem 'rails', '~> X.Y'`
2. Do NOT change `config.load_defaults` yet
3. Generate the new defaults file: `bin/rails app:update`
   This creates `config/initializers/new_framework_defaults_X_Y.rb` with all new defaults commented out
4. Uncomment and test Tier 1 settings first (run full test suite after each)
5. Uncomment and test Tier 2 settings with targeted testing
6. Uncomment and test Tier 3 settings with comprehensive testing
7. Once all settings are enabled and tested, change `config.load_defaults X.Y` and delete the initializer file
8. Run full test suite to verify

**Important:** If `new_framework_defaults_*.rb` exists with uncommented settings from a PREVIOUS upgrade, resolve that before starting the next upgrade.

**Rails 8.2 note:** `rails app:update` now removes `new_framework_defaults_*.rb` automatically
once `config.load_defaults` targets the current Rails version, so step 7 stops being a manual
cleanup.

## Verifying This List

The authoritative per-version default list lives in the Rails configuring guide, under
"Default Values for Target Version X.Y":

```bash
gh api "repos/rails/rails/contents/guides/source/configuring.md?ref=main" \
  --jq '.content' | base64 -d | grep -A15 "Default Values for Target Version 8.1"
```

The generated initializer template is the other source of truth, and it carries the
explanatory comments:

```
railties/lib/rails/generators/rails/app/templates/config/initializers/new_framework_defaults_8_1.rb.tt
```

Use both. The guide is the complete list; the template explains why each one exists.

## Attribution

Self-contained guide written from official Rails documentation and CHANGELOGs.

Last verified against rails/rails on **2026-08-13**.
