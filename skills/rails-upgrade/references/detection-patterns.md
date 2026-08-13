# Detection Patterns for Rails Upgrade

This file contains Grep/Glob patterns organized by version pair. The skill agent reads only the relevant version section and runs each pattern directly against the user's codebase using Grep/Glob/Read tools.

## How to Use These Patterns

The skill agent reads only the relevant version section and applies each pattern directly:

1. Read the section for your target version (e.g., "7.2 → 8.0")
2. For each pattern, call the Grep tool:
   Grep: pattern: "the_pattern" path: "search_path/" output_mode: "content"
3. Run multiple Grep calls in parallel (one message, multiple tool calls)
4. For each finding, record: file path, line number, matching content
5. Pass findings to report generation

If a pattern returns no results: the check is clear (no issue found).
If Grep errors: note it, continue with other patterns.

---

## Version: 5.2 → 6.0

#### require_dependency
- **Grep pattern:** `require_dependency`
- **Search paths:** `app/`, `lib/`
- **Explanation:** Rails 6.0 uses Zeitwerk autoloader — require_dependency is no longer needed and should be removed
- **Fix:** Remove all require_dependency calls. Zeitwerk autoloads everything in app/ and lib/ automatically.
- **Priority:** HIGH

#### Classic autoloader
- **Grep pattern:** `config\.autoloader\s*=\s*:classic`
- **Search paths:** `config/`
- **Explanation:** Classic autoloader deprecated in Rails 6.0; Zeitwerk is now default
- **Fix:** Remove this line. Fix any files that don't match Zeitwerk naming conventions (file name must match constant name).
- **Priority:** HIGH

#### update_attributes
- **Grep pattern:** `update_attributes[^_]`
- **Search paths:** `app/`, `lib/`
- **Explanation:** update_attributes was removed in Rails 6.0
- **Fix:** Replace with `update`
- **Priority:** HIGH

#### before_filter
- **Grep pattern:** `before_filter`
- **Search paths:** `app/controllers/`
- **Explanation:** before_filter was fully removed in Rails 6.0 (deprecated since 5.1)
- **Fix:** Replace with `before_action`
- **Priority:** HIGH

#### skip_before_filter
- **Grep pattern:** `skip_before_filter`
- **Search paths:** `app/controllers/`
- **Explanation:** skip_before_filter fully removed in Rails 6.0
- **Fix:** Replace with `skip_before_action`
- **Priority:** HIGH

#### render nothing: true
- **Grep pattern:** `render.*nothing:\s*true`
- **Search paths:** `app/controllers/`
- **Explanation:** render nothing: true removed in Rails 6.0
- **Fix:** Use `head :ok` or `head :no_content`
- **Priority:** MEDIUM

#### ActiveStorage create_after_upload
- **Grep pattern:** `ActiveStorage::Blob\.create_after_upload`
- **Search paths:** `app/`, `lib/`
- **Explanation:** API changed in Rails 6.0
- **Fix:** Use `ActiveStorage::Blob.create_and_upload!` instead
- **Priority:** MEDIUM

#### belongs_to optional: false
- **Grep pattern:** `belongs_to.*optional:\s*false`
- **Search paths:** `app/models/`
- **Explanation:** belongs_to required by default in Rails 6.0 — optional: false is now redundant (but harmless)
- **Fix:** Remove `optional: false`. Add `optional: true` where nil foreign keys ARE allowed.
- **Priority:** MEDIUM

#### Ruby version check
- **Glob pattern:** `Gemfile`, `.ruby-version`
- **Grep pattern:** `ruby.*['"]2\.[0-4]`
- **Search paths:** `Gemfile`, `.ruby-version`
- **Explanation:** Rails 6.0 requires Ruby 2.5.0+
- **Fix:** Upgrade Ruby to 2.5+ (2.7+ recommended)
- **Priority:** MEDIUM

---

## Version: 6.0 → 6.1

#### legacy_connection_handling
- **Grep pattern:** `legacy_connection_handling`
- **Search paths:** `config/`
- **Explanation:** config.active_record.legacy_connection_handling introduced in 6.1, deprecated behavior
- **Fix:** Do not enable this; migrate to the new connection handling API
- **Priority:** MEDIUM

#### errors[:attribute] string usage
- **Grep pattern:** `errors\[.*\]\s*==\s*['"]|errors\[.*\]\.include`
- **Search paths:** `app/`, `spec/`, `test/`
- **Explanation:** Rails 6.1 changes errors[:attr] to return Error objects, not strings. String comparisons will break.
- **Fix:** Use `errors[:attr].map(&:message)` or `errors.where(:attr).first.message`
- **Priority:** HIGH

#### replace_on_assign_to_many
- **Grep pattern:** `replace_on_assign_to_many`
- **Search paths:** `config/`
- **Explanation:** Active Storage has_many_attached replace behavior changed
- **Fix:** Check file upload behavior; set config explicitly if needed
- **Priority:** MEDIUM

---

## Version: 6.1 → 7.0

#### Webpacker
- **Grep pattern:** `webpacker|javascript_pack_tag`
- **Search paths:** `Gemfile`, `config/`, `app/views/`
- **Explanation:** Rails 7.0 replaces Webpacker with Import Maps or jsbundling-rails
- **Fix:** Migrate to Import Maps (`importmap-rails`), esbuild, or rollup. Remove `webpacker` gem.
- **Priority:** HIGH

#### Turbolinks
- **Grep pattern:** `turbolinks|Turbolinks`
- **Search paths:** `Gemfile`, `app/javascript/`, `app/assets/`
- **Explanation:** Turbolinks replaced by Turbo (Hotwire) in Rails 7.0
- **Fix:** Replace `turbolinks` gem with `turbo-rails`. Update event listeners (turbolinks:load → turbo:load).
- **Priority:** HIGH

#### rails-ujs
- **Grep pattern:** `rails-ujs|@rails/ujs`
- **Search paths:** `Gemfile`, `app/javascript/`, `package.json`
- **Explanation:** Rails UJS replaced by Turbo and Stimulus in Rails 7.0
- **Fix:** Remove rails-ujs. Use Turbo for remote forms, Stimulus for JavaScript behaviors.
- **Priority:** HIGH

#### form_with local option
- **Grep pattern:** `form_with.*local:\s*(true|false)`
- **Search paths:** `app/views/`
- **Explanation:** form_with default changed with Turbo — local: true is no longer needed (now default is remote via Turbo)
- **Fix:** Remove `local: true`. Add `data: { turbo: false }` only where you explicitly want no Turbo.
- **Priority:** HIGH

#### secrets.yml usage
- **Grep pattern:** `Rails\.application\.secrets`
- **Search paths:** `app/`, `lib/`, `config/`
- **Explanation:** Rails.application.secrets deprecated in Rails 7.0; removed in 7.2
- **Fix:** Migrate to `Rails.application.credentials`
- **Priority:** MEDIUM

#### to_s(:format) format
- **Grep pattern:** `\.to_s\(:`
- **Search paths:** `app/`, `lib/`
- **Explanation:** to_s(:format) deprecated in Rails 7.0; use to_fs(:format)
- **Fix:** Replace `.to_s(:format)` with `.to_fs(:format)` or specific methods like `.to_formatted_s`
- **Priority:** MEDIUM

#### ActiveStorage variant resize
- **Grep pattern:** `\.variant\(.*resize:`
- **Search paths:** `app/`
- **Explanation:** ActiveStorage variant syntax changed in Rails 7.0
- **Fix:** Use `variant(resize_to_limit: [w, h])` instead of `variant(resize: "WxH")`
- **Priority:** MEDIUM

#### Ruby version
- **Grep pattern:** `ruby.*['"]2\.[0-6]`
- **Search paths:** `Gemfile`, `.ruby-version`
- **Explanation:** Rails 7.0 requires Ruby 2.7.0+
- **Fix:** Upgrade Ruby to 2.7+ (3.1+ recommended)
- **Priority:** HIGH

---

## Version: 7.0 → 7.1

#### cache_classes
- **Grep pattern:** `cache_classes`
- **Search paths:** `config/environments/`
- **Explanation:** config.cache_classes replaced by config.enable_reloading with INVERTED boolean in Rails 7.1. cache_classes = false → enable_reloading = true
- **Fix:** Replace `config.cache_classes = false` with `config.enable_reloading = true`. Replace `= true` with `= false`.
- **Priority:** HIGH

#### legacy_connection_handling config
- **Grep pattern:** `legacy_connection_handling`
- **Search paths:** `config/`
- **Explanation:** config.active_record.legacy_connection_handling completely removed in Rails 7.1. Will raise error on boot.
- **Fix:** Remove this line entirely. Migrate away from legacy connection handling before upgrading.
- **Priority:** HIGH

#### preview_path singular
- **Grep pattern:** `preview_path\s*=`
- **Search paths:** `config/`
- **Explanation:** config.action_mailer.preview_path (singular) replaced by preview_paths (plural, array) in Rails 7.1
- **Fix:** Change `preview_path = 'path'` to `preview_paths = ['path']`
- **Priority:** HIGH

#### force_ssl = false
- **Grep pattern:** `force_ssl\s*=\s*false`
- **Search paths:** `config/environments/production.rb`
- **Explanation:** force_ssl is now TRUE by default in production in Rails 7.1
- **Fix:** If not using SSL, keep `config.force_ssl = false` explicitly. Otherwise remove the line.
- **Priority:** HIGH

#### lib autoload_paths manual
- **Grep pattern:** `autoload_paths.*lib|eager_load_paths.*lib`
- **Search paths:** `config/application.rb`
- **Explanation:** Rails 7.1 autoloads lib/ by default via autoload_lib. Manual paths may conflict.
- **Fix:** Replace with `config.autoload_lib(ignore: %w[assets tasks])`
- **Priority:** HIGH

#### SQLite db/ location
- **Grep pattern:** `database:\s*db/.*\.sqlite3`
- **Search paths:** `config/database.yml`
- **Explanation:** Rails 7.1 defaults SQLite to storage/ directory
- **Fix:** Either keep existing db/ path explicitly or move databases to storage/
- **Priority:** MEDIUM

#### secrets.yml.enc
- **Grep pattern:** `secrets\.yml\.enc|Rails\.application\.secrets`
- **Search paths:** `config/`, `app/`, `lib/`
- **Explanation:** secrets further deprecated in 7.1, removed in 7.2. Migrate now.
- **Fix:** Migrate to `Rails.application.credentials`
- **Priority:** MEDIUM

---

## Version: 7.1 → 7.2

#### perform_later/deliver_later in transactions
- **Grep pattern:** `perform_later|deliver_later`
- **Search paths:** `app/models/`, `app/controllers/`, `app/services/`
- **Explanation:** Rails 7.2 defers job/email enqueuing until after transaction commits by default. Jobs inside transactions will behave differently.
- **Fix:** Test all jobs/mailers called inside ActiveRecord transactions. Use perform_now for immediate execution if needed.
- **Priority:** HIGH

#### show_exceptions boolean
- **Grep pattern:** `show_exceptions\s*=\s*(true|false)`
- **Search paths:** `config/environments/`
- **Explanation:** show_exceptions requires symbol values in Rails 7.2 — booleans removed
- **Fix:** Change `= true` to `= :all`, `= false` to `= :none` (or `:rescuable`)
- **Priority:** HIGH

#### params comparison
- **Grep pattern:** `params\s*==|==\s*params`
- **Search paths:** `app/controllers/`, `app/`
- **Explanation:** ActionController::Parameters no longer compares equal to Hash in Rails 7.2
- **Fix:** Replace `params == hash` with `params.to_h == hash`
- **Priority:** HIGH

#### ActiveRecord::Base.connection direct
- **Grep pattern:** `ActiveRecord::Base\.connection(?!_pool|_db_config)`
- **Search paths:** `app/`, `lib/`
- **Explanation:** Direct `ActiveRecord::Base.connection` deprecated in Rails 7.2
- **Fix:** Use `ActiveRecord::Base.with_connection { |conn| ... }` or `lease_connection`
- **Priority:** HIGH

#### Rails.application.secrets
- **Grep pattern:** `Rails\.application\.secrets`
- **Search paths:** `app/`, `lib/`, `config/`
- **Explanation:** Rails.application.secrets completely REMOVED in Rails 7.2 (was deprecated in 7.0/7.1)
- **Fix:** Migrate all usages to `Rails.application.credentials`
- **Priority:** HIGH

#### serialize without type
- **Grep pattern:** `serialize\s+:\w+\s*$`
- **Search paths:** `app/models/`
- **Explanation:** serialize now requires explicit type: or coder: parameter in Rails 7.2
- **Fix:** Add `type: YAML` or `type: JSON` to all serialize declarations: `serialize :field, type: Hash`
- **Priority:** MEDIUM

#### fixture_path singular
- **Grep pattern:** `fixture_path[^s]`
- **Search paths:** `test/`, `spec/`, `config/`
- **Explanation:** fixture_path (singular) deprecated in favor of fixture_paths (plural, array) in Rails 7.2
- **Fix:** Change `fixture_path` to `fixture_paths`
- **Priority:** MEDIUM

#### query_constraints
- **Grep pattern:** `query_constraints`
- **Search paths:** `app/models/`
- **Explanation:** query_constraints deprecated in Rails 7.2
- **Fix:** Use `foreign_key` instead
- **Priority:** MEDIUM

#### Mailer test args
- **Grep pattern:** `args:\s*\[`
- **Search paths:** `test/mailers/`, `spec/mailers/`
- **Explanation:** Mailer test helper uses params: instead of args: in Rails 7.2
- **Fix:** Replace `args:` with `params:` in mailer test assertions
- **Priority:** MEDIUM

#### Ruby 3.1+
- **Grep pattern:** `ruby.*['"]3\.0`
- **Search paths:** `Gemfile`, `.ruby-version`
- **Explanation:** Rails 7.2 requires Ruby 3.1+
- **Fix:** Upgrade to Ruby 3.1+ (3.3 recommended)
- **Priority:** MEDIUM

---

## Version: 7.2 → 8.0

#### Sprockets
- **Grep pattern:** `sprockets|Sprockets`
- **Search paths:** `Gemfile`, `config/`, `app/assets/`
- **Explanation:** Rails 8.0 replaces Sprockets with Propshaft as default asset pipeline
- **Fix:** Remove `sprockets-rails` gem, add `propshaft`. Update asset references.
- **Priority:** HIGH

#### Asset pipeline config
- **Grep pattern:** `config\.assets\.`
- **Search paths:** `config/environments/`, `config/initializers/`
- **Explanation:** Asset pipeline configuration changes significantly with Propshaft
- **Fix:** Review all config.assets.* settings; many are Sprockets-specific and must be removed.
- **Priority:** HIGH

#### javascript_include_tag without importmap
- **Grep pattern:** `javascript_include_tag`
- **Search paths:** `app/views/layouts/`
- **Explanation:** Rails 8.0 uses Import Maps — check javascript includes
- **Fix:** Use `javascript_importmap_tags` for Import Maps setups
- **Priority:** HIGH

#### assume_ssl missing
- **Grep pattern:** `force_ssl\s*=`
- **Search paths:** `config/environments/production.rb`
- **Explanation:** Rails 8.0 introduces assume_ssl for SSL behind proxies. Should be set alongside force_ssl.
- **Fix:** Add `config.assume_ssl = true` alongside `config.force_ssl = true`
- **Priority:** HIGH

#### sqlite3_deprecated_warning
- **Grep pattern:** `sqlite3_deprecated_warning`
- **Search paths:** `config/`
- **Explanation:** This config option was removed in Rails 8.0
- **Fix:** Remove this configuration line
- **Priority:** HIGH

#### Redis cache store (inform, not block)
- **Grep pattern:** `redis_cache_store|:redis_store`
- **Search paths:** `config/environments/`
- **Explanation:** Rails 8.0 defaults to Solid Cache — Redis still works but is optional
- **Fix:** Keep Redis if working well, or consider migrating to Solid Cache
- **Priority:** MEDIUM

#### Sidekiq queue adapter (inform)
- **Grep pattern:** `sidekiq|:sidekiq|:async`
- **Search paths:** `config/application.rb`, `config/environments/`
- **Explanation:** Rails 8.0 defaults to Solid Queue — Sidekiq still works
- **Fix:** Keep Sidekiq if needed, or consider Solid Queue for simpler infrastructure
- **Priority:** MEDIUM

#### ActionCable Redis adapter (inform)
- **Grep pattern:** `adapter:\s*redis|:redis`
- **Search paths:** `config/cable.yml`
- **Explanation:** Rails 8.0 defaults to Solid Cable — Redis adapter still works
- **Fix:** Keep Redis if needed, or migrate to Solid Cable
- **Priority:** MEDIUM

#### Database pool config
- **Grep pattern:** `pool:\s*\d+`
- **Search paths:** `config/database.yml`
- **Explanation:** Rails 8.0 restructures database.yml; pool: will be renamed to max_connections: in 8.1
- **Fix:** Review database.yml structure; plan to rename pool: to max_connections: in next hop
- **Priority:** MEDIUM

---

## Version: 8.0 → 8.1

#### Order-dependent finders without an order
- **Grep pattern:** `\.(first|last|second|third|fourth|fifth)\b`
- **Search paths:** `app/`, `lib/`, `test/`, `spec/`
- **Explanation:** Under `load_defaults 8.1`, `#first`/`#last`/etc. raise `ActiveRecord::MissingRequiredOrderError` on a relation with no `order` when the model has no `implicit_order_column`, `query_constraints`, or `primary_key` to fall back on.
- **Fix:** Add an explicit `order`, or set `implicit_order_column` on the model. Models with a normal primary key are unaffected.
- **Priority:** HIGH
- **Note:** Grep is a poor filter here — it matches `Array#first` too. Treat the grep as a scope estimate, then get the real list by enabling `config.active_record.raise_on_missing_required_finder_order_columns = true` in `new_framework_defaults_8_1.rb` and running the full suite. The failures are the authoritative inventory.

#### libvips version and Active Storage variant processor (CVE-2026-66066)
- **Grep pattern:** `variant_processor|ruby-vips|variable_content_types`
- **Search paths:** `config/`, `Gemfile`, `Gemfile.lock`
- **Explanation:** From 8.1.3.1, Active Storage disables libvips unfuzzed loaders. Rails **raises at boot** on libvips `< 8.13`, and BMP/ICO/PSD variants raise. `:vips` is the default processor from `load_defaults 7.0` onward, so absence of the config means the app IS affected.
- **Fix:** Upgrade system libvips to `>= 8.13` and `ruby-vips` to `>= 2.2.1` before the Rails bump. Remove BMP/ICO/PSD from `variable_content_types`.
- **Priority:** HIGH
- **Note:** Check the running libvips with `vips --version`, not the Gemfile — this is a system library, usually pinned in the Dockerfile or base image.

#### SSL commented out
- **Grep pattern:** `#.*force_ssl|#.*assume_ssl`
- **Search paths:** `config/environments/production.rb`
- **Explanation:** Rails 8.1 comments out SSL config by default (assumes Kamal handles SSL termination)
- **Fix:** Uncomment force_ssl and assume_ssl if NOT using Kamal for deployment
- **Priority:** HIGH

#### Path-relative redirects
- **Grep pattern:** `redirect_to\s+[^:'"/]|redirect_to\s+["'][^/]`
- **Search paths:** `app/controllers/`
- **Explanation:** `action_on_path_relative_redirect = :raise` (a `load_defaults 8.1` default) makes `redirect_to "example.com"` raise `UnsafeRedirectError`
- **Fix:** Ensure redirect targets start with `/`. Stage the rollout with `:log` or `:notify` first.
- **Priority:** HIGH

#### SuckerPunch adapter (removed in 8.1)
- **Grep pattern:** `sucker_punch|:sucker_punch`
- **Search paths:** `Gemfile`, `config/`
- **Explanation:** Rails 8.1 **removes** its built-in SuckerPunch adapter — this breaks immediately
- **Fix:** Use `gem 'sucker_punch', '>= 3.2'` which includes its own adapter
- **Priority:** HIGH

#### Built-in Sidekiq adapter (deprecated in 8.1, removed in 8.2)
- **Grep pattern:** `queue_adapter\s*=\s*:sidekiq|:sidekiq`
- **Search paths:** `Gemfile`, `config/application.rb`, `config/environments/`
- **Explanation:** Rails 8.1 only **deprecates** the built-in Sidekiq adapter; it still works. Removal lands in 8.2. Do not confuse this with SuckerPunch, which is removed now.
- **Fix:** Use `gem 'sidekiq', '>= 7.3.3'` which ships its own adapter. Clears the warning and unblocks 8.2.
- **Priority:** MEDIUM

#### Azure storage
- **Grep pattern:** `azure_storage|microsoft_azure|service:\s*Azure`
- **Search paths:** `config/storage.yml`, `Gemfile`
- **Explanation:** Rails 8.1 removes the Azure storage service
- **Fix:** Switch to S3, GCS, or Disk storage. Migrate existing blobs before switching.
- **Priority:** MEDIUM

#### mb_chars / Multibyte::Chars
- **Grep pattern:** `mb_chars|Multibyte::Chars`
- **Search paths:** `app/`, `lib/`
- **Explanation:** Deprecated in 8.1, removed in 8.2. Almost always vestigial — Ruby strings have been encoding-aware since 1.9.
- **Fix:** Delete the `.mb_chars` call. `"foo".mb_chars.upcase` becomes `"foo".upcase`.
- **Priority:** MEDIUM

#### to_time_preserves_timezone
- **Grep pattern:** `to_time_preserves_timezone`
- **Search paths:** `config/`
- **Explanation:** The config is deprecated in 8.1; `:zone` becomes the only behavior
- **Fix:** Set to `:zone`, verify `to_time` behavior across the suite, then remove the line
- **Priority:** MEDIUM

#### ActiveSupport::Configurable
- **Grep pattern:** `ActiveSupport::Configurable`
- **Search paths:** `app/`, `lib/`, `Gemfile.lock`
- **Explanation:** Deprecated in 8.1. Check gems too — some still include it.
- **Fix:** Replace with `class_attribute` declarations or a plain config object
- **Priority:** MEDIUM

#### signed_id_verifier_secret
- **Grep pattern:** `signed_id_verifier_secret`
- **Search paths:** `config/`, `app/models/`
- **Explanation:** Deprecated in favor of `Rails.application.message_verifiers`
- **Fix:** Move the secret into `Rails.application.message_verifiers`. Rotating invalidates existing signed IDs — account for links already sent.
- **Priority:** MEDIUM

#### update_all with CTEs or DISTINCT
- **Grep pattern:** `\.(with|distinct)\b.*update_all|update_all`
- **Search paths:** `app/`, `lib/`
- **Explanation:** `WITH`, `WITH RECURSIVE`, and `DISTINCT` combined with `update_all` are deprecated — the generated SQL was database-dependent and often wrong
- **Fix:** `pluck(:id)` first, then `where(id: ids).update_all(...)`
- **Priority:** MEDIUM

#### Custom ActiveJob serializers
- **Grep pattern:** `ObjectSerializer|ActiveJob::Serializers`
- **Search paths:** `app/`, `lib/`, `config/initializers/`
- **Explanation:** Custom serializers must expose `#klass` publicly in 8.1
- **Fix:** Move `def klass` above the `private` keyword
- **Priority:** MEDIUM

#### Action Text Trix APIs
- **Grep pattern:** `to_trix_html|TrixAttachment|TrixConversion|to_trix_content_attachment_partial_path`
- **Search paths:** `app/`, `lib/`
- **Explanation:** All deprecated in 8.1 as Action Text decouples from Trix
- **Fix:** Replace `to_trix_html` with `to_s`. Rewrite `TrixAttachment` subclasses against the editor-agnostic API.
- **Priority:** MEDIUM

#### rake stats / STATS_DIRECTORIES
- **Grep pattern:** `rake stats|STATS_DIRECTORIES`
- **Search paths:** `lib/tasks/`, `config/`, `.github/`, `Rakefile`
- **Explanation:** Both removed in 8.1
- **Fix:** Use `bin/rails stats` and `Rails::CodeStatistics.register_directory`
- **Priority:** LOW

#### Benchmark.ms and Time arithmetic removals
- **Grep pattern:** `Benchmark\.ms`
- **Search paths:** `app/`, `lib/`, `config/`
- **Explanation:** `Benchmark.ms` removed in 8.1, along with passing a `Time` to `Time#since` and adding a `Time` to a `TimeWithZone`
- **Fix:** Use `ActiveSupport::Benchmark.realtime(:float_millis)`
- **Priority:** LOW

#### SQLite3 :retries and MySQL unsigned column methods
- **Grep pattern:** `retries:|unsigned_float|unsigned_decimal|unsigned:\s*true`
- **Search paths:** `config/database.yml`, `db/migrate/`
- **Explanation:** `:retries` (SQLite3) and `:unsigned_float`/`:unsigned_decimal` (MySQL) are removed in 8.1. The `unsigned: true` option is deprecated, not removed.
- **Fix:** Use `timeout:` for SQLite3. Use `t.float`/`t.decimal` plus a check constraint for MySQL.
- **Priority:** LOW

#### Route to multiple paths
- **Grep pattern:** `get\s+\[|post\s+\[|match\s+\[`
- **Search paths:** `config/routes.rb`
- **Explanation:** Routing one route to multiple paths is removed in 8.1
- **Fix:** Split into separate route declarations
- **Priority:** LOW

#### Semicolon in query strings
- **Grep pattern:** `param.*;|url.*;|href.*[^;];`
- **Search paths:** `app/`, `lib/`
- **Explanation:** Rails 8.1 removes semicolon as a query parameter separator
- **Fix:** Replace semicolons (;) with ampersands (&) in manually constructed query strings
- **Priority:** LOW

#### bundler-audit absent
- **Grep pattern:** `bundler-audit`
- **Search paths:** `Gemfile`, `bin/`, `config/`
- **Explanation:** Rails 8.1 ships bundler-audit as a default security scanning tool
- **Fix:** Add `gem 'bundler-audit', require: false` to the development/test group, run `bundle exec bundler-audit check --update`
- **Priority:** LOW

#### pool: in database.yml
- **Grep pattern:** `pool:`
- **Search paths:** `config/database.yml`
- **Explanation:** Rails 8.1 renames `pool:` to `max_connections:` alongside new `keepalive`, `max_age`, and `min_connections` options. **`pool:` still works** — this is a rename to adopt, not a break.
- **Fix:** Replace all `pool:` with `max_connections:` for consistency with the new option names
- **Priority:** LOW

---

## Version: 8.1 → 8.2 (UNRELEASED)

Rails 8.2 is `8.2.0.alpha` on `main`. Run these patterns while on 8.1 to prepare — every fix
below works on 8.1. Re-verify against `main` before acting.

#### Ruby version below 3.3.1
- **Grep pattern:** `ruby ["']|^\d+\.\d+`
- **Search paths:** `.ruby-version`, `Gemfile`, `Dockerfile`, `.github/workflows/`
- **Explanation:** Rails 8.2 raises `required_ruby_version` to `>= 3.3.1` (from `>= 3.2.0`)
- **Fix:** Bump Ruby to 3.3.1+ **while still on Rails 8.1** and get a green suite before touching the Rails version
- **Priority:** HIGH

#### Active Record 6.1 marshalling format
- **Grep pattern:** `marshalling_format_version|load_defaults`
- **Search paths:** `config/application.rb`, `config/initializers/`
- **Explanation:** The 6.1 marshalling format is removed in 8.2. Apps that never call `load_defaults`, or call it with 6.1 or lower, are implicitly on the old format — cached AR objects become unreadable.
- **Fix:** Set `config.active_record.marshalling_format_version = 7.1` on 8.1, deploy, then flush or expire every cache holding marshalled AR objects. **Do this before upgrading.**
- **Priority:** HIGH

#### Negative enum scopes
- **Grep pattern:** `not_[a-z_]+|enum\s+:`
- **Search paths:** `app/models/`, `app/controllers/`, `app/jobs/`
- **Explanation:** `Book.not_published` now also returns records where the enum column is `nil`. Silent change — more rows, no error.
- **Fix:** Add `.where.not(column: nil)` where `nil` should stay excluded. Prioritize scopes feeding deletion, billing, or notification logic.
- **Priority:** HIGH

#### Database minimum versions
- **Grep pattern:** `postgres|sqlite|image:.*pg|image:.*postgres`
- **Search paths:** `Dockerfile`, `docker-compose.yml`, `.github/workflows/`, `config/database.yml`
- **Explanation:** Rails 8.2 requires SQLite `>= 3.35.0` and PostgreSQL `>= 10.0`
- **Fix:** Check `sqlite3 --version` and `SELECT version()` in every environment. CI images and developer machines drift behind production.
- **Priority:** HIGH

#### protect_from_forgery without a strategy
- **Grep pattern:** `protect_from_forgery`
- **Search paths:** `app/controllers/`
- **Explanation:** Calling it without `:with` is deprecated; the default moves from `:null_session` to `:exception` under `load_defaults 8.2`
- **Fix:** Pass `with:` explicitly at every call site, or set `config.action_controller.default_protect_from_forgery_with`. API endpoints relying on `:null_session` must say so.
- **Priority:** MEDIUM

#### require_dependency
- **Grep pattern:** `require_dependency`
- **Search paths:** `app/`, `lib/`, `config/`
- **Explanation:** Deprecated in 8.2 with removal targeted at 9.0. Already a no-op under Zeitwerk.
- **Fix:** Delete the call
- **Priority:** MEDIUM

#### RedisCacheStore on the redis gem
- **Grep pattern:** `redis_cache_store|DEFAULT_REDIS_OPTIONS|gem ["']redis["']`
- **Search paths:** `Gemfile`, `config/environments/`, `config/initializers/`
- **Explanation:** `RedisCacheStore` is reimplemented on `redis-client >= 0.28.0` instead of `redis >= 4.0.1`. Custom connection blocks and option hashes may not carry over.
- **Fix:** Add `redis-client` to the Gemfile. Review custom `redis:` connection setup. Replace `DEFAULT_REDIS_OPTIONS` references.
- **Priority:** MEDIUM

#### ImageProcessing implicit backend
- **Grep pattern:** `image_processing|ruby-vips|mini_magick`
- **Search paths:** `Gemfile`, `Gemfile.lock`
- **Explanation:** ImageProcessing 2.0 no longer pulls in a backend — `ruby-vips` or `mini_magick` must be declared explicitly
- **Fix:** Add `gem "ruby-vips"` (or `mini_magick`) to the Gemfile
- **Priority:** MEDIUM

#### preprocessed attachments
- **Grep pattern:** `preprocessed:\s*true`
- **Search paths:** `app/models/`
- **Explanation:** Deprecated in favor of `process: :immediately`
- **Fix:** Replace `preprocessed: true` with `process: :immediately`
- **Priority:** MEDIUM

#### MIME and renderer registration after boot
- **Grep pattern:** `Mime::Type\.register|Mime::SET|Mime::LOOKUP|Mime::EXTENSION_LOOKUP|Renderers::RENDERERS|register_tracker`
- **Search paths:** `config/initializers/`, `app/`, `lib/`
- **Explanation:** The MIME registry and dependency-tracker registry freeze after initialization — late registration will raise `FrozenError`. The `Mime::SET`/`LOOKUP`/`EXTENSION_LOOKUP` and `Renderers::RENDERERS` constants are deprecated.
- **Fix:** Move registration into `config/initializers/mime_types.rb`. Swap the constants for `Mime.symbols`, `Mime::Type.lookup`, `Mime::Type.lookup_by_extension`, and `Renderers.all`.
- **Priority:** MEDIUM

#### Adapter options deprecated for 9.0
- **Grep pattern:** `strict:|schema_order|insert_returning|use_insert_returning\?|auto_populated\?|write_attribute\(:id`
- **Search paths:** `config/database.yml`, `app/models/`, `lib/`
- **Explanation:** MySQL `strict`, PostgreSQL `schema_order` / `insert_returning`, `Column#auto_populated?`, and `write_attribute(:id, ...)` are all deprecated with a 9.0 removal target
- **Fix:** Mechanical renames — `variables: { sql_mode: "..." }`, `schema_search_path`, `prefetch_primary_key?`, `auto_populated_on_insert?`, `#id=`
- **Priority:** MEDIUM

#### safe_join without a separator
- **Grep pattern:** `safe_join\([^,)]+\)`
- **Search paths:** `app/helpers/`, `app/views/`, `lib/`
- **Explanation:** `safe_join` no longer falls back to the `$,` global when no separator is passed
- **Fix:** Pass the separator explicitly: `safe_join(parts, "")`
- **Priority:** MEDIUM

#### ERB handler configuration
- **Grep pattern:** `Handlers::ERB|erb_implementation|erb_trim_mode`
- **Search paths:** `config/initializers/`, `config/application.rb`
- **Explanation:** `ActionView::Template::Handlers::ERB` is now private API; configuration moves to `ActionView::Base`
- **Fix:** Move ERB configuration (trim mode, escape handling) onto `ActionView::Base`
- **Priority:** MEDIUM

#### SKIP_TEST_DATABASE_TRUNCATE and id assertions (MySQL)
- **Grep pattern:** `SKIP_TEST_DATABASE_TRUNCATE|id:\s*1\b|\.id\s*==\s*\d`
- **Search paths:** `.github/workflows/`, `test/`, `spec/`, `config/`
- **Explanation:** MySQL parallel test databases reset with `DELETE` instead of `TRUNCATE`, so auto-increment counters no longer reset. `SKIP_TEST_DATABASE_TRUNCATE` has no effect.
- **Fix:** Remove the env var from CI. Fix tests asserting on literal record ids — they were always fragile.
- **Priority:** MEDIUM

#### Content negotiation with wildcard Accept
- **Grep pattern:** `respond_to|format\.(html|json)`
- **Search paths:** `app/controllers/`
- **Explanation:** `strict_accept_header = true` makes `Accept: application/json, */*` return JSON instead of defaulting to HTML
- **Fix:** Enable the flag alone and exercise every content-negotiated route. This can flip the response format of existing endpoints.
- **Priority:** MEDIUM

---

## Attribution

Patterns derived from:
- OmbuLabs.ai / FastRuby.io (MIT) — detection-scripts/patterns/ from claude-code_rails-upgrade-skill
- Mario Alberto Chávez Cárdenas (MIT) — patterns from rails-upgrade-skill
- Official Rails CHANGELOGs (MIT)
