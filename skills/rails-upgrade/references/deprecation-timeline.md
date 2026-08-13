# Deprecation Timeline

Track when deprecations were introduced, when they become warnings, and when they are removed. Fix deprecations as soon as they appear — don't wait for removal. Each version's deprecation warnings are telling you exactly what will break in the next version.

## Deprecation Lifecycle

```
Version N:     Feature works normally
               ↓
Version N+1:   DEPRECATED — shows warnings in logs/tests
               ↓ (typically 1-2 minor versions)
Version N+2:   REMOVED — raises errors
```

The gap between "deprecated" and "removed" is your window. Use it.

Last verified against rails/rails on **2026-08-13**. Rails 8.2 is unreleased
(`8.2.0.alpha` on `main`); rows targeting 8.2 and 9.0 are subject to change.

---

## Timeline by Version

### Removed in Rails 6.0 (deprecated earlier in 5.x)

| Feature | Deprecated In | Removed In | Replacement |
|---------|--------------|------------|-------------|
| `update_attributes` | 5.x | 6.0 | `update` |
| `before_filter` / `after_filter` / `around_filter` | 5.1 | 6.0 | `before_action` / `after_action` / `around_action` |
| `render nothing: true` | 5.x | 6.0 | `head :ok` |

---

### Removed in Rails 7.1 (deprecated in 7.0)

| Feature | Deprecated In | Removed In | Replacement |
|---------|--------------|------------|-------------|
| `to_s(:format)` on Date/Time/Numeric | 7.0 | 7.1 | `to_fs(:format)` |

---

### Removed in Rails 7.2 (deprecated in 7.0–7.1)

| Feature | Deprecated In | Removed In | Replacement |
|---------|--------------|------------|-------------|
| `Rails.application.secrets` | 7.0 | 7.2 | `Rails.application.credentials` |
| `config.cache_classes` | 7.1 | 7.2 | `config.enable_reloading` (logic is inverted!) |
| `config.preview_path` (singular) | 7.1 | 7.2 | `config.preview_paths` (array) |
| `config.action_dispatch.show_exceptions` boolean | 7.1 | 7.2 | Symbols: `:all`, `:rescuable`, or `:none` |
| `params == hash` comparison | 7.1 | 7.2 | `params.to_h == hash` |
| `ActiveRecord::Base.connection` (direct call) | 7.1 | 7.2 | `with_connection { |conn| ... }` block |

Note on `cache_classes`: the meaning is **inverted**. `cache_classes: false` (don't cache = do reload) becomes `enable_reloading: true`.

---

### Removed in Rails 8.0 (deprecated in 7.2)

| Feature | Deprecated In | Removed In | Replacement |
|---------|--------------|------------|-------------|
| `query_constraints` | 7.2 | 8.0 | `foreign_key` |
| `serialize` old syntax | 7.2 | 8.0 | `serialize :attr, type: X, coder: Y` |
| `fixture_path` (singular) | 7.2 | 8.0 | `fixture_paths` (plural array) |
| `to_default_s` | 7.2 | 8.0 | `to_s` |
| Sprockets (as default asset pipeline) | 7.2 | 8.0 | Propshaft (or keep Sprockets explicitly) |
| `ActiveRecord::ConnectionPool#connection` | 7.2 | 8.0 | `with_connection { |conn| ... }` |
| `ActiveSupport::ProxyObject` | 7.2 | 8.0 | `BasicObject` |

---

### Removed in Rails 8.1 (deprecated in 7.2–8.0)

| Feature | Deprecated In | Removed In | Replacement |
|---------|--------------|------------|-------------|
| Semicolon (`;`) as query string separator | 8.0 | 8.1 | Ampersand (`&`) only |
| Built-in SuckerPunch ActiveJob adapter | 8.0 | 8.1 | sucker_punch gem 3.2+ (ships its own adapter) |
| Azure Storage service in Active Storage | 8.0 | 8.1 | S3, GCS, or Disk |
| Skipping leading brackets in parameter names | 8.0 | 8.1 | Well-formed parameter names |
| Routing one route to multiple paths | 8.0 | 8.1 | Separate route declarations |
| `:retries` option for the SQLite3 adapter | 8.0 | 8.1 | `timeout:` |
| `:unsigned_float` / `:unsigned_decimal` MySQL columns | 8.0 | 8.1 | `t.float` / `t.decimal` + a check constraint |
| `bin/rake stats`, `STATS_DIRECTORIES` | 8.0 | 8.1 | `bin/rails stats`, `Rails::CodeStatistics.register_directory` |
| `rails/console/methods.rb` | 8.0 | 8.1 | Console helpers are loaded automatically |
| Passing a `Time` to `Time#since` | 8.0 | 8.1 | Pass a numeric duration |
| `Benchmark.ms` | 8.0 | 8.1 | `ActiveSupport::Benchmark.realtime(:float_millis)` |
| Adding a `Time` to an `ActiveSupport::TimeWithZone` | 8.0 | 8.1 | Add a duration, not a `Time` |
| `to_time` preserving system local time | 7.2 | 8.1 | `to_time` returns a zone-aware time |
| `enqueue_after_transaction_commit` symbol values | 8.0 | 8.1 | Per-job boolean (global config returns in 8.2) |

⚠️ **Not removed in 8.1, despite a common misreading:** the built-in **Sidekiq** adapter was
only *deprecated* in 8.1. It is removed in 8.2. SuckerPunch — removed in 8.1 — is the one that
breaks immediately. Upgrade `sidekiq` to `>= 7.3.3` anyway; it clears the warning and prepares
for 8.2.

**Not a deprecation:** `pool:` in `database.yml` was *renamed* to `max_connections:` in 8.1,
alongside the new `keepalive`, `max_age`, and `min_connections` options. Default behavior is
unchanged and `pool:` still works. Adopt the new name; do not treat it as a break.

**Not a deprecation:** the old form helper names (`text_area`, `check_box`, `rich_text_area`)
are **not** deprecated. Rails 8.0 added `textarea`, `checkbox`, and `rich_textarea` as
*aliases*. Both spellings work, with no removal scheduled.

---

### Deprecated in Rails 8.1 → removed in Rails 8.2

This is the actionable list for anyone on 8.1 today. Every fix works on 8.1.

| Feature | Deprecated In | Removed In | Replacement |
|---------|--------------|------------|-------------|
| Built-in Sidekiq ActiveJob adapter | 8.1 | 8.2 | sidekiq gem 7.3.3+ (ships its own adapter) |
| `String#mb_chars`, `ActiveSupport::Multibyte::Chars` | 8.1 | 8.2 | Plain String methods (encoding-aware since Ruby 1.9) |
| Unordered `#first`/`#last` without order columns | 8.1 | 8.2 | Explicit `order`, or `implicit_order_column` on the model |
| `active_record.marshalling_format_version = 6.1` | earlier | 8.2 | `7.1` — **flush caches before upgrading** |
| `config.active_support.to_time_preserves_timezone` | 8.1 | 8.2+ | `:zone` becomes the only behavior |
| `ActiveSupport::Configurable` | 8.1 | 8.2+ | `class_attribute`, or a plain config object |
| `ActiveRecord::Base.signed_id_verifier_secret` | 8.1 | 8.2+ | `Rails.application.message_verifiers` |
| `insert_all`/`upsert_all` via an unpersisted association | 8.1 | 8.2+ | Persist the owner first, or insert on the class |
| `WITH` / `WITH RECURSIVE` / `DISTINCT` with `update_all` | 8.1 | 8.2+ | `pluck(:id)`, then `where(id: ids).update_all` |
| Custom job serializers with a private `#klass` | 8.1 | 8.2+ | Make `#klass` public |
| Action Text Trix APIs (`to_trix_html`, `TrixAttachment`, …) | 8.1 | 8.2+ | `to_s` / the editor-agnostic Action Text API |
| `render` with `:renderable` lacking keyword args | 8.1 | 8.2+ | `def render_in(view_context, **options, &block)` |
| `config.action_dispatch.ignore_leading_brackets` | 8.1 | 8.2+ | Remove the config |

---

### Deprecated in Rails 8.2 → removal targeted at Rails 9.0

Rails 8.2 is unreleased (`8.2.0.alpha` on `main`). Verify before relying on this.

| Feature | Deprecated In | Removal Target | Replacement |
|---------|--------------|----------------|-------------|
| `require_dependency` | 8.2 | 9.0 | Delete it — a no-op under Zeitwerk |
| MySQL `strict` option in `database.yml` | 8.2 | 9.0 | `variables: { sql_mode: "..." }` |
| PostgreSQL `schema_order` option | 8.2 | 9.0 | `schema_search_path` |
| `protect_from_forgery` without a strategy | 8.2 | 9.0 | Explicit `with:`, or `default_protect_from_forgery_with` |
| `Mime::SET`, `Mime::LOOKUP`, `Mime::EXTENSION_LOOKUP` | 8.2 | 9.0 | `Mime.symbols`, `Mime::Type.lookup`, `lookup_by_extension` |
| `ActionController::Renderers::RENDERERS` | 8.2 | 9.0 | `add_renderer` / `remove_renderer` / `Renderers.all` |
| `ActionDispatch::Cookies::HTTP_HEADER` | 8.2 | 9.0 | `Rack::SET_COOKIE` |
| `write_attribute(:id, value)` for primary keys | 8.2 | 9.0 | The model's `#id=` |
| `Column#auto_populated?` | 8.2 | 9.0 | `auto_populated_on_insert?` |
| `supports_pgcrypto_uuid?` | 8.2 | 9.0 | Unnecessary at PostgreSQL 10.0+ |
| PostgreSQL `insert_returning` / `use_insert_returning?` | 8.2 | 9.0 | `prefetch_primary_key?` |
| `RedisCacheStore::DEFAULT_REDIS_OPTIONS` | 8.2 | 9.0 | Configure `redis-client` directly |
| `preprocessed: true` on attachments | 8.2 | 9.0 | `process: :immediately` |
| Built-in `resque`, `delayed_job`, `backburner`, `sneakers`, `queue_classic` adapters | 8.2 | 9.0 | Gem-supplied adapters, or Solid Queue / GoodJob |
| `Mail::Address.wrap` | 8.2 | 9.0 | Unused; remove the call |
| Late `Mime::Type.register` / `DependencyTracker.register_tracker` | 8.2 | 9.0 | Register during initialization (raises `FrozenError` later) |

---

## Finding Deprecation Warnings

### During test runs

```bash
# Run tests and show deprecation warnings
bundle exec rspec 2>&1 | grep "DEPRECATION WARNING"
bundle exec rails test 2>&1 | grep "DEPRECATION WARNING"

# Save to file for review
bundle exec rspec 2>&1 | grep "DEPRECATION WARNING" > deprecations.txt

# Count and rank unique deprecations
sort deprecations.txt | uniq -c | sort -rn
```

### Configure test environment

```ruby
# config/environments/test.rb

# Fail tests immediately on any deprecation (strict — recommended during upgrades)
config.active_support.deprecation = :raise

# Show warnings without failing (useful for an initial audit pass)
config.active_support.deprecation = :stderr
```

### Disallow specific deprecations (Rails 6.1+)

```ruby
# config/environments/test.rb
config.active_support.disallowed_deprecation_warnings = [
  "cache_classes is deprecated"
]
config.active_support.disallowed_deprecation = :raise
```

### Track deprecations in production

```ruby
# config/initializers/deprecation_tracking.rb
ActiveSupport::Notifications.subscribe("deprecation.rails") do |name, start, finish, id, payload|
  Rails.logger.warn "DEPRECATION: #{payload[:message]}"
  # Optionally forward to error tracking:
  # Honeybadger.notify(payload[:message])
  # Sentry.capture_message(payload[:message])
end
```

---

## Best Practices

1. **Fix deprecations immediately** when they appear — don't batch them up for later
2. **Run after every gem update**: `bundle exec rails test 2>&1 | grep "DEPRECATION"`
3. **Treat deprecation warnings as bugs** — they are future errors with a countdown timer
4. **Never skip a version** — each version's warnings are roadmaps to the next version's failures
5. **Document each fix** with a comment showing the old and new approach, so the team understands why the change was made

---

## Attribution

Based on:
- Mario Alberto Chávez Cárdenas (MIT) — deprecations-timeline.md from rails-upgrade-skill
- OmbuLabs.ai / FastRuby.io (MIT) — deprecation-warnings.md from claude-code_rails-upgrade-skill
