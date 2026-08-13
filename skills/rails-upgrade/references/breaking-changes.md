# Breaking Changes by Rails Version

Reference document for the Rails upgrade skill. Covers all breaking changes from Rails 5.2 through 8.2.
Organized by version pair with HIGH / MEDIUM / LOW priority tables.

Last verified against rails/rails on **2026-08-13**. Rails 8.2 is unreleased
(`8.2.0.alpha` on `main`) — treat that section as a moving target and re-verify before use.

---

## Summary Statistics

| Version Pair | Total Changes | HIGH | MEDIUM | LOW | Difficulty | Time Estimate |
|---|---|---|---|---|---|---|
| 5.2 → 6.0 | ~15 | 5 | 6 | 4 | Hard | 1-2 weeks |
| 6.0 → 6.1 | ~10 | 3 | 4 | 3 | Medium | 3-5 days |
| 6.1 → 7.0 | ~12 | 5 | 5 | 2 | Hard | 1-2 weeks |
| 7.0 → 7.1 | 12 | 5 | 4 | 3 | Medium | 2-4 hours |
| 7.1 → 7.2 | 38 | 5 | 12 | 21 | Hard | 4-8 hours |
| 7.2 → 8.0 | 13 | 5 | 4 | 4 | Very Hard | 6-12 hours |
| 8.0 → 8.1 | ~28 | 9 | 11 | 8 | Medium | 1-2 days |
| 8.1 → 8.2 (unreleased) | ~25 | 7 | 12 | 6 | Medium | 1-2 days |

---

## Rails 5.2 → 6.0

**Difficulty: Hard**
**Time estimate: 1-2 weeks**

The Zeitwerk autoloader is the dominant change. Every file in the app must follow strict naming conventions. Also significant: removal of long-deprecated methods (`update_attributes`, `before_filter`, `render nothing: true`) and a new default CSRF strategy.

### HIGH Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 1 | **Zeitwerk autoloader replaces classic autoloader** | Files with names that do not match their constant name cause `NameError: uninitialized constant`. The classic autoloader is deprecated and will warn loudly. | `config/application.rb`, `config/initializers/`, every file in `app/` and `lib/` | Set `config.load_defaults 6.0`. Remove `config.autoloader = :classic`. Rename any file where the filename does not exactly correspond to the CamelCase constant it defines (e.g., `html_parser.rb` must define `HtmlParser`). Use `bin/rails zeitwerk:check` to find violations. |
| 2 | **require_dependency removed** | `require_dependency` calls raise `NoMethodError` or are silently ignored under Zeitwerk, breaking load order assumptions. | `app/**/*.rb`, `lib/**/*.rb` | Remove every `require_dependency` call. Zeitwerk handles eager loading automatically. For code that genuinely needs a class available before autoloading, use `require` with an explicit path, but this is rarely needed. |
| 3 | **update_attributes / update_attributes! removed** | `NoMethodError` on every model save path that used these methods. This was deprecated since Rails 5.x; Rails 6.0 removes them entirely. | `app/models/**/*.rb`, `app/controllers/**/*.rb`, `lib/**/*.rb`, `spec/**/*.rb`, `test/**/*.rb` | Replace all `update_attributes(params)` with `update(params)`. Replace all `update_attributes!(params)` with `update!(params)`. Run a global search for `update_attributes` to catch every occurrence. |
| 4 | **before_filter / after_filter / skip_before_filter removed** | `NoMethodError` in any controller that uses these methods. Deprecated since Rails 5.1. | `app/controllers/**/*.rb` | Replace `before_filter` with `before_action`. Replace `after_filter` with `after_action`. Replace `around_filter` with `around_action`. Replace `skip_before_filter` with `skip_before_action`. Replace `skip_after_filter` with `skip_after_action`. |
| 5 | **protect_from_forgery default changed to :exception** | The CSRF protection strategy in `ApplicationController` now defaults to raising an `ActionController::InvalidAuthenticityToken` exception instead of resetting the session. This can expose unexpected exception-handling gaps. | `app/controllers/application_controller.rb` | If you previously relied on session-reset behavior, add `protect_from_forgery with: :null_session` explicitly. If you already had `with: :exception`, the explicit declaration is now redundant but harmless. Review error handling for `ActionController::InvalidAuthenticityToken`. |

### MEDIUM Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 6 | **Ruby 2.5+ required** | Rails 6.0 will not boot on Ruby < 2.5. | `Gemfile`, `.ruby-version`, CI configuration | Upgrade Ruby to at least 2.5. Ruby 2.7 is recommended for forward compatibility toward Rails 7.x, which requires Ruby 2.7. |
| 7 | **ActiveStorage::Blob.create_after_upload! removed** | `NoMethodError` wherever blobs are created programmatically. | All code that calls `ActiveStorage::Blob.create_after_upload!` | Replace with `ActiveStorage::Blob.create_and_upload!`. The new method name is more descriptive of the two-step operation. |
| 8 | **render nothing: true removed** | `ArgumentError: :nothing option is no longer supported` | `app/controllers/**/*.rb` | Replace `render nothing: true` with `head :ok`. Replace `render nothing: true, status: :created` with `head :created`. Use `head <status>` for any status code. |
| 9 | **belongs_to required by default (Rails 5.0 opt-in now default)** | Validation errors on models where the foreign key is intentionally nil. Note: this was technically introduced in Rails 5.0 as opt-in; in 6.0 it is fully the default. | `app/models/**/*.rb` | Add `optional: true` to every `belongs_to` association where a nil foreign key is intentional (e.g., polymorphic associations that can be unset). |
| 10 | **Webpacker replaces Sprockets as default JS pipeline** | Sprockets is still included for CSS and images, but new apps default to Webpacker for JavaScript. Existing apps may see JS bundling break if they switch. | `Gemfile`, `config/webpacker.yml`, `app/javascript/` | If staying with Sprockets for JS: add `gem 'webpacker'` is not required; ensure `gem 'sprockets', '~> 4.0'` is present. If migrating to Webpacker: run `rails webpacker:install` and move JS to `app/javascript/`. |
| 11 | **ActionCable configuration API changes** | Cable connections may fail with outdated adapter configuration. | `config/cable.yml`, `config/environments/*.rb` | Review `config/cable.yml`. Update adapter names if using Redis (verify gem name `redis` vs `hiredis`). Review channel authentication if using Devise or Warden. |

### LOW Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 12 | **Action Mailbox introduced** | No breaking change, but conflicts possible with `mail_room` gem or custom inbound mail routing. | `app/mailboxes/`, `Gemfile` | Check for conflicts with existing mail-handling gems. Run `rails action_mailbox:install` only if you intend to adopt it. |
| 13 | **Action Text introduced** | No breaking change unless you already have a `rich_text` database column or a gem conflict with `trix`. | `app/models/**/*.rb`, `Gemfile` | Run `rails action_text:install` only if you want rich text editing. Check for column name conflicts. |
| 14 | **ActionDispatch::Http::UploadedFile#to_io removed** | Code that called `to_io` on uploaded files will fail. | `app/**/*.rb` | Use `uploaded_file.open` or `uploaded_file.read` instead. |
| 15 | **Multiple database support (basic) added** | New configuration options available; no breaking change for single-database apps. | `config/database.yml` | No action required unless adopting multi-database. New `config.active_record.primary_abstract_class` option available. |

---

## Rails 6.0 → 6.1

**Difficulty: Medium**
**Time estimate: 3-5 days**

The most significant change is the transformation of `model.errors[:attribute]` from returning strings to returning `ActiveModel::Error` objects. Any code that treats errors as plain strings will silently produce wrong output or raise errors. The `replace_on_assign_to_many` change affects file upload behavior.

### HIGH Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 1 | **ActiveRecord errors[:attribute] returns Error objects, not strings** | `model.errors[:name]` now returns an array of `ActiveModel::Error` objects. Code that calls string methods directly (e.g., `errors[:name].first.upcase`, or concatenating into a string) will produce wrong output. `errors.full_messages` still works. | `app/views/**/*.erb`, `app/views/**/*.haml`, `app/helpers/**/*.rb`, `app/models/**/*.rb`, `spec/**/*.rb`, `test/**/*.rb` | Audit every location that reads from `model.errors[:attribute]`. To get the string message, call `.message` on the Error object, or use `errors.full_messages_for(:attribute)`. In RSpec matchers like `include("can't be blank")`, switch to `include(a_string_matching(...))` or use `errors.full_messages`. |
| 2 | **replace_on_assign_to_many behavior change for has_many_attached** | Assigning a new set of files to a `has_many_attached` association now replaces existing files by default. Previously it appended. This can cause silent data loss if your UI expects append behavior. | `app/models/**/*.rb` anywhere `has_many_attached` is used, all file upload controllers and forms | Audit every `has_many_attached` assignment. If you need append behavior, set `config.active_storage.replace_on_assign_to_many = false` in `config/application.rb` (deprecated but available as escape hatch). Long term, use explicit `attach` calls for append behavior. |
| 3 | **Strict loading mode introduced** | When `strict_loading` is enabled on a model or query, `ActiveRecord::StrictLoadingViolationError` is raised on any lazy association load. Only affects code that explicitly opts in, but it changes how N+1 queries surface. | `app/models/**/*.rb`, `config/application.rb` | No action required unless you enable `config.active_record.strict_loading_by_default`. If you do enable it, fix all N+1 queries by adding explicit `includes`/`preload`/`eager_load` calls. |

### MEDIUM Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 4 | **destroy_all on loaded relation changes** | Calling `destroy_all` on an already-loaded ActiveRecord relation now deletes records but does not update the in-memory collection the same way as before. Code that relies on the collection being empty after `destroy_all` may behave unexpectedly. | `app/models/**/*.rb`, `app/controllers/**/*.rb` | After calling `destroy_all`, call `reload` on the association if you need to read it again. Do not assume the in-memory relation reflects the database state post-deletion. |
| 5 | **Horizontal sharding support added** | New `connected_to(role:, shard:)` API may conflict with custom sharding implementations. | `app/models/**/*.rb`, `config/database.yml` | If using a custom sharding solution, verify it does not conflict with the new built-in API. Review `config/database.yml` if you have multiple databases configured. |
| 6 | **config.active_record.legacy_connection_handling introduced** | New option that changes how connections are returned to the pool in multi-database setups. Defaults to `true` for existing apps upgrading; new apps default to `false`. | `config/application.rb` | For existing apps: the option will be `true` by default (old behavior preserved). Plan to set it to `false` before Rails 7.0, which removes the legacy mode entirely. |
| 7 | **Ruby 2.5 still minimum; 2.7 recommended** | Ruby 2.5 and 2.6 will reach end of life soon. Rails 7.0 requires Ruby 2.7. | `Gemfile`, `.ruby-version` | Upgrade to Ruby 2.7 now to avoid a forced upgrade when moving to 7.0. |

### LOW Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 8 | **ActionMailbox improvements** | New routing and processing options; no breaking changes to existing configurations. | `app/mailboxes/` | Review release notes if using ActionMailbox. |
| 9 | **New connected_to API additions** | `connected_to` now accepts `shard:` keyword. Existing calls with only `role:` continue to work. | `app/**/*.rb` | No action required unless you need sharding. |
| 10 | **config.active_record.legacy_connection_handling = false path** | If you proactively set this to `false` in 6.1, test your multi-database connection handling carefully. | `config/application.rb` | Set to `false` in 6.1 to prepare for 7.0, but verify with full test suite. |

---

## Rails 6.1 → 7.0

**Difficulty: Hard**
**Time estimate: 1-2 weeks**

The move to Hotwire (Turbo + Stimulus) replacing Turbolinks and Webpacker is the dominant change. Most apps will need significant JavaScript restructuring. Also: `config.active_record.legacy_connection_handling` is removed, Ruby 2.7+ required.

### HIGH Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 1 | **Webpacker removed from Rails core** | Webpacker is no longer a default dependency. Apps built on Webpacker must migrate to jsbundling-rails, importmap-rails, or another bundler. | `Gemfile`, `app/javascript/`, `config/webpacker.yml`, `package.json`, layout files | Choose a replacement: `importmap-rails` (no build step, recommended for simple apps), `jsbundling-rails` with esbuild/rollup/webpack (for complex JS). Run the appropriate install generator. Remove `webpacker` gem. |
| 2 | **Turbolinks replaced by Turbo (Hotwire)** | `Turbolinks.visit()`, `data-turbolinks-*` attributes, and Turbolinks JavaScript events are gone. Turbo has a different API and event names. | `app/javascript/**/*.js`, `app/views/**/*.erb`, `app/views/**/*.html.*` | Replace `data-turbolinks-action` with `data-turbo-action`. Replace `turbolinks:load` event with `turbo:load`. Replace `Turbolinks.visit()` with `Turbo.visit()`. Remove `gem 'turbolinks'` and add `gem 'turbo-rails'`. Run `rails turbo:install`. |
| 3 | **config.active_record.legacy_connection_handling removed** | Apps that had `config.active_record.legacy_connection_handling = true` will error on boot. | `config/application.rb`, `config/environments/*.rb` | Remove the setting. If it was `false`, just remove it. If it was `true`, you need to update your multi-database connection handling code to use the new non-legacy approach before upgrading. |
| 4 | **Ruby 2.7+ required** | Rails 7.0 will not boot on Ruby < 2.7. | `Gemfile`, `.ruby-version`, CI configuration | Upgrade to Ruby 2.7 minimum. Ruby 3.0 or 3.1 recommended for forward compatibility. |
| 5 | **ActiveSupport::Dependencies::Loadable removed** | Internal autoloading hooks that some gems relied on are gone. Third-party gems that monkey-patched the old autoloader will break. | `Gemfile` | Update all gems to versions compatible with Zeitwerk. Run `bundle update` and check for Zeitwerk-related errors. Use `bin/rails zeitwerk:check`. |

### MEDIUM Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 6 | **Encryption API added (Active Record Encryption)** | No breaking change, but new `encrypts` declaration available. If you have a custom encryption solution, verify it does not conflict. | `app/models/**/*.rb` | No action required unless adopting the new API. Check for conflicts with `attr_encrypted` or similar gems. |
| 7 | **query_log_tags added** | New SQL comment annotation feature. No breaking change, but may add unexpected SQL comments in logs. | `config/application.rb` | Opt in via `config.active_record.query_log_tags_enabled = true`. No action required if not enabling. |
| 8 | **belongs_to optional default (enforcement)** | Rails 7.0 more strictly enforces `belongs_to required: true` by default. Models that previously passed validation with nil foreign keys may now fail. | `app/models/**/*.rb`, `test/**/*.rb`, `spec/**/*.rb` | Audit all `belongs_to` associations. Add `optional: true` where nil is intentional. Fix failing tests. |
| 9 | **Sprockets 4.x required** | If using Sprockets, version 3.x is no longer supported. | `Gemfile` | Upgrade to `gem 'sprockets', '~> 4.0'`. Update `config/initializers/assets.rb` if present. Some `//= require_tree .` directives need to be explicit in Sprockets 4. |
| 10 | **ActionDispatch::Response#content_type changes** | The `content_type` method now returns only the MIME type without charset. Code testing `response.content_type == "text/html; charset=utf-8"` will fail. | `test/**/*.rb`, `spec/**/*.rb` | Update assertions to use `assert_equal "text/html", response.media_type` and check charset separately via `response.charset`. |

### LOW Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 11 | **Stimulus 3.x (Hotwire)** | If using Stimulus, update to Stimulus 3 as part of Hotwire migration. | `app/javascript/controllers/` | Run `rails stimulus:install` after setting up Hotwire. Stimulus 3 is backwards compatible with Stimulus 2 for basic usage. |
| 12 | **at_css / at_xpath removed from ActionView** | Rarely used helper methods removed. | `app/views/**/*.erb` | No action required unless these helpers are used. |

---

## Rails 7.0 → 7.1

**Difficulty: Medium**
**Time estimate: 2-4 hours**

Several high-priority config changes with subtle gotchas. The `cache_classes` → `enable_reloading` rename is especially dangerous because the boolean meaning is inverted. Every environment file must be updated.

### HIGH Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 1 | **cache_classes renamed to enable_reloading (boolean INVERTED)** | Setting `config.cache_classes = false` (old development default: reload on each request) must become `config.enable_reloading = true`. Setting `config.cache_classes = true` (old production default: do not reload) must become `config.enable_reloading = false`. Using the old key raises a deprecation warning in 7.1 and an error in 7.2. | `config/environments/development.rb`, `config/environments/production.rb`, `config/environments/test.rb`, any custom environments | In development: change `config.cache_classes = false` to `config.enable_reloading = true`. In production and test: change `config.cache_classes = true` to `config.enable_reloading = false`. Remove the old key. Do not simply rename — the boolean is inverted. |
| 2 | **force_ssl enabled by default in production** | New production apps default to `config.force_ssl = true`. Upgrading apps that had it commented out may now have it silently enabled via `load_defaults 7.1`, causing redirect loops if SSL is not configured. | `config/environments/production.rb` | Explicitly set `config.force_ssl = false` if your app does not terminate SSL at the Rails level (e.g., SSL is handled by a load balancer and you don't want double-redirect). If you want SSL enforcement, leave it enabled or set it explicitly to `true`. |
| 3 | **config.action_mailer.preview_path → preview_paths (array)** | The singular `preview_path` option is deprecated. In 7.1 it still works with a warning; it will be removed in a future version. | `config/application.rb`, `config/environments/development.rb` | Rename `config.action_mailer.preview_path` to `config.action_mailer.preview_paths`. The value changes from a single string to an array: `config.action_mailer.preview_paths = [Rails.root.join("test/mailers/previews")]`. |
| 4 | **SQLite database defaults to storage/ directory** | New apps default SQLite databases to `storage/development.sqlite3` instead of `db/development.sqlite3`. Existing apps upgrading will not be affected if `config/database.yml` already has explicit paths, but running `app:update` may overwrite the config. | `config/database.yml` | If your `database.yml` has explicit file paths, no action required. If you run `rails app:update`, review the generated `database.yml` before accepting changes. Do not move an existing database file without updating the path. |
| 5 | **lib/ autoloaded by default; manual autoload_paths may conflict** | If you previously added `lib/` to `config.autoload_paths` manually, you may now get double-loading warnings or constant errors. Rails 7.1 adds `lib/` to autoload paths automatically (with the caveat that `lib/assets`, `lib/tasks`, and `lib/generators` are excluded). | `config/application.rb` | Remove manual `config.autoload_paths << Rails.root.join("lib")` if present. Use `config.autoload_lib(ignore: %w[assets tasks generators])` instead. Files in `lib/` must follow Zeitwerk naming conventions. |

### MEDIUM Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 6 | **Query log tags sqlcommenter format** | New `sqlcommenter` format available for query log tags. No breaking change, but format change may affect log parsing tools. | `config/application.rb` | No action required. Opt in via `config.active_record.query_log_tags_format = :sqlcommenter` only if desired. |
| 7 | **Cache format version 7.1** | A new, more efficient cache format is available. Old and new format caches are not interchangeable during a rolling deploy. | `config/application.rb` | Do not change `config.active_support.cache_format_version` until all servers in a cluster are running Rails 7.1. After full deployment, set `config.active_support.cache_format_version = 7.1` and flush your cache. |
| 8 | **Content Security Policy initializer** | CSP API has new helpers. No breaking change, but existing initializers may produce deprecation warnings. | `config/initializers/content_security_policy.rb` | Review and update CSP initializer. Run the app and check for CSP-related deprecation warnings in logs. |
| 9 | **ActionText attachment changes** | ActionText attachment handling updated. Verify that existing rich text content renders correctly after upgrade. | `app/views/**/*.erb` with ActionText content, stored rich text records | After upgrading, view existing rich text content and verify attachments render correctly. Run `rails action_text:install:migrations` if prompted. |

### LOW Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 10 | **New /up health check route** | Rails automatically mounts a `/up` health check route. This may conflict with an existing `/up` route. | `config/routes.rb` | Check if your app defines a `/up` route. If it does, rename your route or disable the default with `config.action_dispatch.health_check_path = false`. |
| 11 | **Verbose job logs in development** | New development logging shows more ActiveJob detail. No breaking change; may increase log noise. | `config/environments/development.rb` | No action required. Configure `config.active_job.verbose_enqueue_logs` if desired. |
| 12 | **Dockerfile generation** | Running `rails app:update` now generates a `Dockerfile` and related files. | `Dockerfile`, `.dockerignore` | Review generated Dockerfile before committing. No breaking change. |

---

## Rails 7.1 → 7.2

**Difficulty: Hard**
**Time estimate: 4-8 hours**

This version has 38 documented changes, many of which are deprecations graduating to removals. The transaction-aware job change is a major behavior change that can silently alter when jobs execute. `Rails.application.secrets` is removed entirely.

### HIGH Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 1 | **Transaction-aware job enqueuing (behavior change)** | Jobs and mailers enqueued inside an ActiveRecord transaction now wait for the transaction to commit before being picked up. Previously, a job could be enqueued before the transaction committed, leading to race conditions. This is now the correct behavior, but it changes the timing of job execution. Jobs inside rolled-back transactions are now discarded. | `app/models/**/*.rb`, `app/controllers/**/*.rb`, `app/jobs/**/*.rb`, `app/mailers/**/*.rb` — anywhere `perform_later` or `deliver_later` is called inside a `transaction` block | Audit all transaction blocks. If you enqueue jobs inside transactions intentionally expecting them to run even on rollback, this behavior has changed. If you need the old behavior, wrap the enqueue in `after_commit`. Most apps benefit from the new behavior as it eliminates a class of race conditions. |
| 2 | **show_exceptions changed from boolean to symbol** | `config.action_dispatch.show_exceptions = true` or `= false` is no longer valid. Must use `:all`, `:rescuable`, or `:none`. `:all` = show all exceptions (old `true`). `:none` = do not show any (old `false`). `:rescuable` = show only exceptions handled by `rescue_from`. | `config/environments/development.rb`, `config/environments/production.rb`, `config/environments/test.rb` | Change `config.action_dispatch.show_exceptions = true` to `config.action_dispatch.show_exceptions = :all`. Change `config.action_dispatch.show_exceptions = false` to `config.action_dispatch.show_exceptions = :none`. |
| 3 | **ActionController::Parameters no longer equals Hash** | `params == { key: value }` no longer returns `true`. This comparison was always semantically incorrect (params have security semantics that hashes do not), but it used to return `true` for convenience. Now it always returns `false`. | `app/controllers/**/*.rb`, `test/**/*.rb`, `spec/**/*.rb` | Replace `params == some_hash` with `params.to_h == some_hash` or `params.to_unsafe_h == some_hash`. In tests, use `expect(response.parsed_body).to eq(...)` instead of comparing params directly. |
| 4 | **ActiveRecord::Base.connection deprecated** | `ActiveRecord::Base.connection` is deprecated. It was a class-level method that returned a connection from the pool without a guaranteed return path, which could cause connection leaks. | `app/**/*.rb`, `lib/**/*.rb`, `config/initializers/**/*.rb`, `db/seeds.rb` | Replace with `ActiveRecord::Base.connection_pool.with_connection { |conn| ... }` or use `ActiveRecord::Base.lease_connection` for single queries. For most use cases, avoid direct connection access; let ActiveRecord manage connections through normal model queries. |
| 5 | **Rails.application.secrets removed** | `Rails.application.secrets` is completely gone. This was deprecated in Rails 6.x. Any code reading `Rails.application.secrets.some_key` will raise `NoMethodError`. | `config/secrets.yml`, `config/secrets.yml.enc`, anywhere `Rails.application.secrets` is referenced | Migrate all secrets to `Rails.application.credentials`. Run `rails credentials:edit` to add secrets. Replace all `Rails.application.secrets.key` calls with `Rails.application.credentials.key`. Remove `config/secrets.yml`. Update environment-specific credential files if needed. |

### MEDIUM Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 6 | **serialize requires type: or coder: parameter** | Calling `serialize :attribute` without a type or coder raises an error in 7.2. Previously, bare `serialize` defaulted to marshaling. | `app/models/**/*.rb` | Replace `serialize :column` with `serialize :column, type: Array` or `serialize :column, type: Hash` or `serialize :column, coder: JSON` depending on what the column stores. For arbitrary objects, use `serialize :column, coder: Marshal` to preserve old behavior (not recommended; prefer JSON). |
| 7 | **query_constraints deprecated in favor of foreign_key** | `query_constraints` on associations is deprecated. This was an experimental feature from Rails 7.1. | `app/models/**/*.rb` | Replace `query_constraints` with the appropriate `foreign_key` option. Review Rails 7.2 release notes for the exact migration path for your association type. |
| 8 | **ActionMailer test syntax: args: renamed to params:** | In mailer tests, the `args:` keyword argument is renamed to `params:`. | `test/mailers/**/*.rb`, `spec/mailers/**/*.rb` | Find all mailer test helpers that use `args:` and rename to `params:`. Example: `assert_enqueued_email_with MyMailer, :welcome, args: [user]` becomes `assert_enqueued_email_with MyMailer, :welcome, params: [user]`. |
| 9 | **fixture_path renamed to fixture_paths (array)** | `config.fixture_path` (singular string) is deprecated. Must use `config.fixture_paths` (plural array). | `config/application.rb`, `test/test_helper.rb` | Rename `config.fixture_path = Rails.root.join("test/fixtures")` to `config.fixture_paths = [Rails.root.join("test/fixtures")]`. Note it is now an array. |
| 10 | **ActiveSupport::Cache deprecated methods** | `to_default_s` and `clone_empty` on cache stores are deprecated and will be removed in 7.3. | `config/application.rb`, custom cache store implementations | Audit custom cache stores. Remove calls to deprecated methods. |
| 11 | **autoload_lib syntax change** | The `%w()` variant of the ignore argument is deprecated in favor of `%w[]`. | `config/application.rb` | Change `config.autoload_lib(ignore: %w(assets tasks))` to `config.autoload_lib(ignore: %w[assets tasks])`. |
| 12 | **Ruby 3.1+ required** | Rails 7.2 requires Ruby 3.1 or later. | `Gemfile`, `.ruby-version`, CI configuration | Upgrade to Ruby 3.1 minimum. Ruby 3.3 is recommended. Run your test suite against the new Ruby version before upgrading Rails. |

### LOW Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 13–33 | **21 additional deprecations** | Various minor deprecations. See the official Rails 7.2 release notes for the complete list. Most are method renames or option changes in rarely-used APIs. | Various | Run your full test suite after upgrading and address all deprecation warnings shown in the log output. Set `config.active_support.deprecation = :raise` in the test environment to turn deprecation warnings into errors during testing. |
| 34 | **allow_browser minimum versions feature** | New `allow_browser versions: :modern` controller method. No breaking change. | `app/controllers/application_controller.rb` | Optional adoption. If added, test that your supported browsers meet the minimum version requirements. |
| 35 | **DevContainers support added** | New devcontainer files generated by `rails app:update`. No breaking change. | `.devcontainer/` | Review generated files if you use Dev Containers. |

---

## Rails 7.2 → 8.0

**Difficulty: Very Hard**
**Time estimate: 6-12 hours**

The replacement of Sprockets with Propshaft as the default asset pipeline is the most disruptive change. Any app with non-trivial asset configuration will need significant work. Solid gems (Solid Cache, Solid Queue, Solid Cable) are now defaults, replacing Redis-backed solutions in the Rails default stack.

### HIGH Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 1 | **Sprockets replaced by Propshaft as default asset pipeline** | Sprockets is no longer included by default. If your app uses Sprockets, you must either explicitly keep it (`gem 'sprockets-rails'`) or migrate to Propshaft. Propshaft has a fundamentally simpler model: it does not support asset compilation directives (`//= require`). Assets are served by digest fingerprinting only. | `Gemfile`, `app/assets/`, `config/initializers/assets.rb`, layout files, `app/views/**/*.erb` | Option A (keep Sprockets): add `gem 'sprockets-rails'` to Gemfile. Update `config/application.rb` if needed. Option B (migrate to Propshaft): add `gem 'propshaft'`. Remove all `//= require` and `//= require_tree` directives from `.css` and `.js` manifests. Propshaft serves files by path, not by manifest. Update layout tags. Test all asset loading in production mode. |
| 2 | **Multi-database config restructured for Solid Cache/Queue/Cable** | The default `config/database.yml` for new apps includes separate databases for `primary`, `cache`, `queue`, and `cable`. Upgrading apps that do not adopt the Solid gems may have an incompatible `database.yml` after running `rails app:update`. | `config/database.yml`, `config/environments/*.rb` | Review `config/database.yml` carefully after running `rails app:update`. If not adopting Solid gems, you do not need the extra database entries. Remove or skip the generated cache/queue/cable database sections. |
| 3 | **Solid Cache, Solid Queue, Solid Cable as defaults** | New apps default to database-backed cache, job queue, and Action Cable. Existing apps are not forced to switch, but `rails app:update` will add these to Gemfile and config. Redis-backed setups may conflict with new defaults. | `Gemfile`, `config/cache.yml`, `config/queue.yml`, `config/cable.yml`, `config/environments/production.rb` | If keeping Redis: remove or do not add the Solid gems; keep your existing cache/queue/cable configuration. If adopting Solid gems: run `rails solid_cache:install`, `rails solid_queue:install`, `rails solid_cable:install` and create the required database migrations. |
| 4 | **config.assume_ssl setting introduced** | New `config.assume_ssl = true` is added to production config in new apps. This tells Rails to treat all requests as if they arrived over SSL (useful when SSL is terminated at a load balancer and Rails only sees plain HTTP). Without this, `request.ssl?` returns `false` even for HTTPS traffic, which can cause incorrect redirect URLs. | `config/environments/production.rb` | If you terminate SSL at a proxy or load balancer: add `config.assume_ssl = true`. If you terminate SSL at Rails directly: do not set this (or set to `false`). Review all `request.ssl?` checks and `force_ssl` behavior. |
| 5 | **Removed deprecated APIs** | Several deprecated APIs are removed: `sqlite3_deprecated_warning` configuration, `use_big_decimal_serializer`, `ActiveSupport::ProxyObject`. Any code using these will fail with `NoMethodError` or `NameError`. | `config/application.rb`, `app/**/*.rb`, `lib/**/*.rb`, custom serializers | Search for `sqlite3_deprecated_warning`, `use_big_decimal_serializer`, and `ProxyObject` across the codebase. Remove or replace each occurrence. For `ActiveSupport::ProxyObject`, use `BasicObject` or `Delegator` instead. |

### MEDIUM Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 6 | **Thruster gem for HTTP/2 and asset compression** | New apps include `thruster` in the Gemfile for HTTP/2 push and X-Sendfile acceleration. No breaking change for existing apps, but the Dockerfile changes. | `Gemfile`, `Dockerfile` | If adopting Thruster: add `gem 'thruster'` and update Dockerfile per the Rails 8 template. If not adopting: no action required. |
| 7 | **Kamal deployment integration** | Rails 8 includes Kamal 2 for deployment. New `config/deploy.yml` generated by `rails app:update`. If using a different deployment system, the generated file is safe to ignore but review before committing. | `config/deploy.yml`, `Dockerfile` | Review `config/deploy.yml` after `rails app:update`. If using Heroku, Fly.io, or another platform, the file can be removed or ignored. |
| 8 | **PWA manifest routes** | New apps get a `manifest.json` and `serviceworker.js` route. No breaking change, but `rails app:update` adds these files and routes. | `config/routes.rb`, `app/views/pwa/`, `app/controllers/` | Review new PWA-related files after `rails app:update`. Remove if not building a PWA. |
| 9 | **Environment config updates** | Various production and development defaults changed in the generated environment files. Running `rails app:update` surfaces these as conflicts. | `config/environments/*.rb` | Review each conflict from `rails app:update` carefully. Do not blindly accept all changes — compare your customizations against the new defaults. |

### LOW Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 10 | **params.expect() new API** | New `params.expect(:key)` method as a safer alternative to `params.require(:key).permit(...)`. No breaking change. | `app/controllers/**/*.rb` | Optional adoption. Useful for cleaner controller params handling. |
| 11 | **Built-in authentication generator** | `rails generate authentication` creates a full authentication scaffold. No breaking change; does not affect existing auth. | `app/models/`, `app/controllers/` | Adopt only if replacing an existing auth solution. Check for conflicts with Devise or other auth gems before running the generator. |
| 12 | **Form helper aliases added** | `textarea`, `checkbox`, `rich_textarea` are new aliases for `text_area`, `check_box`, `rich_text_area`. Old names still work. | `app/views/**/*.erb` | No action required. Existing view code is unaffected. |
| 13 | **script/ folder** | A new `script/` folder is generated for one-off scripts, as an alternative to `lib/tasks/`. | `script/` | No action required. |

---

## Rails 8.0 → 8.1

**Difficulty: Medium**
**Time estimate: 1-2 days**

Not the trivial hop it first appears. The single most disruptive change is
`ActiveRecord::MissingRequiredOrderError` — under `load_defaults 8.1`, calling `#first`,
`#last`, or `#second` on an unordered relation whose model has no order columns now raises.
That pattern is everywhere in older codebases and in test suites. Beyond that, 8.1 is a heavy
deprecation release: several APIs deprecated here are removed in 8.2, so clearing them now is
the cheapest time to do it.

**Target the newest patch, `8.1.3.1` or later.** `8.1.3.1` (2026-07-29) fixes
CVE-2026-66066, a critical Active Storage arbitrary-file-read / RCE. See the "Active Storage
libvips hardening" entry below — the fix has real behavior consequences.

### HIGH Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 1 | **Order-dependent finders raise without an order** | With `config.active_record.raise_on_missing_required_finder_order_columns = true` (a `load_defaults 8.1` default), `#first`, `#last`, `#second`, etc. raise `ActiveRecord::MissingRequiredOrderError` when called on a relation with no `order` values **and** the model has no `implicit_order_column`, `query_constraints`, or `primary_key` to fall back on. The old non-raising behavior is deprecated and the escape-hatch config is removed in 8.2. | `app/**/*.rb`, `lib/**/*.rb`, `test/**/*.rb`, `spec/**/*.rb` — anywhere `.first`/`.last` is called on a relation | Add an explicit `order` to each affected call, or set `implicit_order_column` on the model. Models backed by a normal primary key are unaffected. Enable the flag in `new_framework_defaults_8_1.rb` first and run the full suite — this surfaces as a wave of test failures, not a boot error. |
| 2 | **force_ssl and assume_ssl commented out in production config** | New Rails 8.1 apps have `force_ssl` and `assume_ssl` commented out by default. The assumption is that Kamal or another reverse proxy handles SSL termination. Upgrading apps that had these settings enabled may find them silently disabled after running `rails app:update` and accepting the new config. | `config/environments/production.rb` | If NOT using Kamal or a proxy that handles SSL: explicitly uncomment and set `config.force_ssl = true` and `config.assume_ssl = true` as appropriate. If using Kamal with SSL offloading: the commented-out defaults are correct. Review your deployment topology before accepting this change. |
| 3 | **Active Storage libvips hardening (CVE-2026-66066)** | Shipped in 8.1.3.1 / 8.0.5.1 / 7.2.3.2. Active Storage now disables libvips "unfuzzed" loaders and savers. Two consequences: **(a)** Rails **raises during boot** if libvips is older than 8.13, because older libvips cannot block those operations at all; **(b)** variant transformation of **BMP, ICO, and PSD** now raises. | `Gemfile.lock` (`ruby-vips`), system libvips, `config/storage.yml`, anywhere `variable_content_types` is configured | Upgrade system libvips to `>= 8.13` **before** the Rails upgrade, or the app will not boot. Bump `ruby-vips` to `>= 2.2.1`. Remove BMP/ICO/PSD from `variable_content_types` and plan a fallback for existing attachments of those types. If the app was exposed to untrusted uploads on an affected version, rotate `secret_key_base`, the master key, and every credential reachable from the process. |
| 4 | **Built-in SuckerPunch adapter removed; built-in Sidekiq adapter deprecated** | `:sucker_punch` no longer resolves to a built-in adapter — it is **removed** in 8.1. `:sidekiq` still works in 8.1 but emits a deprecation warning; the built-in Sidekiq adapter is **removed in 8.2**. Getting these two confused is easy: only SuckerPunch breaks now. | `config/application.rb`, `config/environments/*.rb`, `Gemfile` | Upgrade to `sucker_punch >= 3.2` (ships its own adapter) — required now. Upgrade to `sidekiq >= 7.3.3` (ships its own adapter) — required before 8.2, and it silences the warning today. No config change is needed beyond the gem upgrade; the gems register the adapters. |
| 5 | **Path-relative redirects raise** | `config.action_controller.action_on_path_relative_redirect = :raise` is a `load_defaults 8.1` default. `redirect_to "example.com"` or `redirect_to "@attacker.com"` (relative URLs with no leading slash) now raise `ActionController::Redirecting::UnsafeRedirectError`. This closes an open-redirect vector. | `app/controllers/**/*.rb` | Audit every `redirect_to` taking a dynamic or string-built target. Ensure paths start with `/`. To stage the change, set `:log` (the previous default) or `:notify` and watch the logs before flipping to `:raise`. |
| 6 | **JSON responses no longer escape HTML entities and line separators** | `config.action_controller.escape_json_responses = false` and `config.active_support.escape_js_separators_in_json = false` are `load_defaults 8.1` defaults. `render json: { key: "  <>&" }` previously emitted `{"key":"  <>&"}` and now emits the raw characters. Safe in modern browsers (ECMAScript 2019 made U+2028/U+2029 valid in string literals) but **not** safe if you interpolate rendered JSON directly into an HTML `<script>` block or into a non-browser consumer that assumed escaping. | `app/controllers/**/*.rb`, `app/views/**/*.erb` embedding JSON, any downstream JSON consumer | Grep views for JSON interpolated into `<script>` tags. If any exist, either fix them to use `json_escape`/`safe` serialization or keep `escape_json_responses = true` explicitly. |
| 7 | **Azure Active Storage service removed** | `config.active_storage.service = :azure` and `ActiveStorage::Service::AzureStorageService` are removed. | `config/storage.yml`, `config/environments/*.rb` | Switch to S3-compatible storage, Google Cloud Storage, or the Disk service, or extract the Azure adapter into a separate gem. **Migrate existing blobs before switching services.** |
| 8 | **Semicolon query string separator removed** | `?key=value;other=value2` is no longer parsed. Only `&` is accepted. Semicolons now land inside the preceding parameter's value instead of splitting. | `app/controllers/**/*.rb`, any URLs generated or consumed by the app | Search for semicolons in query string generation. Replace `;` separators with `&`. If consuming external APIs that use semicolons, parse them yourself. |
| 9 | **`schema.rb` table columns sorted alphabetically** | Active Record now dumps table columns alphabetically rather than in creation order, so schema dumps stop flip-flopping with migration order. The first `db:migrate` after the upgrade rewrites `schema.rb` with a very large, mostly-noise diff. **This was reverted on `main` for 8.2** because alphabetical ordering produces improper production tables under `db:prepare` — so expect a second large diff when you reach 8.2. | `db/schema.rb` | Regenerate `schema.rb` in a dedicated commit so the reordering does not hide real changes. Apps that need exact column order preserved should switch to `config.active_record.schema_format = :sql` and use `structure.sql`. |

### MEDIUM Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 10 | **`pool:` renamed to `max_connections:` in database.yml** | 8.1 introduces `keepalive`, `max_age`, and `min_connections` connection options and renames `pool` to `max_connections` for consistency. **There is no change to default behavior and `pool:` continues to work as an alias** — this is a rename to adopt, not a break to race. | `config/database.yml` | Rename every `pool:` key to `max_connections:` across all sections and named databases. Do it in one pass so the vocabulary matches the new `min_connections`/`max_age`/`keepalive` neighbours. |
| 11 | **`ActiveSupport::Multibyte::Chars` and `String#mb_chars` deprecated** | Both emit deprecation warnings in 8.1 and are **removed in 8.2**. Most `mb_chars` calls are vestigial — Ruby strings have been encoding-aware since 1.9. | `app/**/*.rb`, `lib/**/*.rb` | Delete the `.mb_chars` call. `"foo".mb_chars.upcase` becomes `"foo".upcase`. For genuinely locale-sensitive casing, use `ActiveSupport::Inflector` or the `unicode` gem. |
| 12 | **`config.active_support.to_time_preserves_timezone` deprecated** | The config itself is deprecated; `:zone` (the `load_defaults 7.2` value) becomes the only behavior. Apps still on the old `to_time` semantics get warnings. | `config/application.rb`, `config/initializers/new_framework_defaults_*.rb` | Set the value to `:zone`, verify `to_time` behavior across the suite, then remove the config line entirely. |
| 13 | **`ActiveSupport::Configurable` deprecated** | The mixin is deprecated. Gems and app code that `include ActiveSupport::Configurable` will warn. | `app/**/*.rb`, `lib/**/*.rb`, `Gemfile.lock` | Replace with plain `class_attribute` declarations or a `Struct`/`Data` config object. Check third-party gems too — some still include it. |
| 14 | **`ActiveRecord::Base.signed_id_verifier_secret` deprecated** | Deprecated in favor of `Rails.application.message_verifiers`, which centralizes verifier configuration and rotation. | `config/initializers/**/*.rb`, `app/models/**/*.rb` | Move the secret into `Rails.application.message_verifiers`, or set `signed_id_verifier` directly. Rotating this invalidates existing signed IDs — plan for links already in the wild. |
| 15 | **`insert_all` / `upsert_all` with unpersisted records in associations deprecated** | Calling these through an association whose owner (or whose collection) holds unpersisted records now warns; the behavior was ambiguous about what gets written. | `app/models/**/*.rb`, `app/**/*.rb` | Persist the owner first, or call `insert_all` on the model class with explicit foreign keys rather than through the association. |
| 16 | **`WITH`, `WITH RECURSIVE`, and `DISTINCT` with `update_all` deprecated** | Combining CTEs or `DISTINCT` with `update_all` produced database-dependent and often wrong SQL. Now deprecated. | `app/models/**/*.rb`, `lib/**/*.rb` | Resolve the relation to a set of ids first (`.pluck(:id)`), then `where(id: ids).update_all(...)`. |
| 17 | **ActiveJob `enqueue_after_transaction_commit` symbol values removed** | `:never`, `:always`, and `:default` are no longer accepted for `ActiveJob::Base.enqueue_after_transaction_commit`, and the global `config.active_job.enqueue_after_transaction_commit` was removed in 8.1. (Note: 8.2 **restores** the global config as a plain boolean.) | `config/application.rb`, `config/environments/*.rb`, `app/jobs/**/*.rb` | Remove the symbol values. Set the per-job boolean `self.enqueue_after_transaction_commit = true/false` where you need to override. On 8.2 you can move back to the global config. |
| 18 | **Custom ActiveJob serializers must expose a public `#klass`** | Serializers that defined `klass` as `private` now warn and will break. | `app/serializers/**/*.rb`, `lib/**/*.rb`, `config/initializers/active_job.rb` | Move `def klass` above the `private` keyword in every custom `ActiveJob::Serializers::ObjectSerializer` subclass. |
| 19 | **Action Text Trix APIs deprecated** | `ActionText::TrixAttachment`, `ActionText::Attachments::TrixConversion`, `ActionText::Attachable#to_trix_content_attachment_partial_path`, `ActionText::RichText#to_trix_html`, and `ActionText::Content#to_trix_html` are all deprecated as Action Text decouples from Trix. | `app/models/**/*.rb`, `app/views/**/*.erb`, `app/helpers/**/*.rb` | Replace `to_trix_html` with `to_s` / `to_rendered_html`. If you subclass or monkey-patch `TrixAttachment`, plan a rewrite against the editor-agnostic API. |
| 20 | **`render` with `:renderable` objects lacking keyword args deprecated** | Objects passed as `renderable:` that define `#render_in` without accepting keyword arguments now warn. | `app/controllers/**/*.rb`, `app/models/**/*.rb`, component classes | Change `def render_in(view_context)` to `def render_in(view_context, **options, &block)`. |
| 21 | **bundler-audit integration** | Rails 8.1 adds `bundler-audit` as a default security scanning tool with a `bin/bundler-audit` script and a CI step. Apps with custom CI may need to wire it in. | `Gemfile`, `bin/`, `.github/workflows/` | Add `gem 'bundler-audit', require: false` to the development/test group. Run `bundle exec bundler-audit check --update`. Add the step to CI. |

### LOW Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 22 | **New Action View defaults: `render_tracker` and hidden-field autocomplete** | `config.action_view.render_tracker = :ruby` switches template dependency tracking from regex scanning to a real Ruby parser (more accurate; may change which templates get recompiled). `config.action_view.remove_hidden_field_autocomplete = true` drops `autocomplete="off"` from hidden fields generated by `form_tag`, `token_tag`, `method_tag`, and `button_to`. | `app/views/**/*`, HTML snapshot tests | Adopt both. If HTML-diffing tests fail on the missing `autocomplete` attribute, update the fixtures rather than reverting the flag. |
| 23 | **Assorted Active Support removals** | Removed: passing a `Time` to `Time#since`; `Benchmark.ms`; adding a `Time` to an `ActiveSupport::TimeWithZone`; `to_time` preserving the system local time. | `app/**/*.rb`, `lib/**/*.rb` | Grep for `Benchmark.ms` and replace with `ActiveSupport::Benchmark.realtime(:float_millis)`. The `Time` arithmetic removals raise clearly; fix at the call site. |
| 24 | **Assorted Active Record removals** | Removed: the `:retries` option for the SQLite3 adapter; the `:unsigned_float` and `:unsigned_decimal` column methods for MySQL. | `config/database.yml`, `db/migrate/**/*.rb` | Delete `retries:` from the SQLite3 config (use `timeout:`). Replace `t.unsigned_float` / `t.unsigned_decimal` with `t.float` / `t.decimal` plus a check constraint. |
| 25 | **Assorted Action Pack removals** | Removed: skipping over leading brackets in parameter names; using semicolons as a query string separator (see HIGH #8); routing one route to multiple paths. `config.action_dispatch.ignore_leading_brackets` is deprecated. | `config/routes.rb`, `config/application.rb` | Split any route declared with an array of paths into separate `get`/`post` declarations. Remove `ignore_leading_brackets`. |
| 26 | **Railties removals: `bin/rake stats`, `STATS_DIRECTORIES`, `rails/console/methods.rb`** | `rake stats` is gone (use `bin/rails stats`), the `STATS_DIRECTORIES` constant is removed, and the deprecated `rails/console/methods.rb` file no longer exists. | `lib/tasks/**/*.rake`, `config/initializers/**/*.rb`, CI scripts | Replace `rake stats` invocations with `bin/rails stats`. Register extra directories via `Rails::CodeStatistics.register_directory` instead of `STATS_DIRECTORIES`. |
| 27 | **MySQL `unsigned: true` in migrations deprecated** | `t.integer :column, unsigned: true` warns. Unsigned integer support through Active Record is being phased out. Distinct from the `:unsigned_float`/`:unsigned_decimal` removals in #24. | `db/migrate/**/*.rb` | For new migrations use `t.integer :column` plus `add_check_constraint :table, "column >= 0", name: "non_negative_column"`. Existing columns are unaffected at the database level. |
| 28 | **.gitignore updated with `/config/*.key`** | The generated `.gitignore` now includes `/config/*.key` to prevent accidental credential key commits. | `.gitignore` | Add `/config/*.key` if not present. Verify `config/credentials.yml.enc` is tracked but `config/master.key` and environment-specific `.key` files are not. |

---

## Rails 8.1 → 8.2 (UNRELEASED)

**Difficulty: Medium**
**Time estimate: 1-2 days**
**Status: `8.2.0.alpha` on `main` — not released. Do not upgrade production to this.**

This section exists so you can (a) triage 8.1 deprecation warnings that name 8.2 as the
removal version and (b) prepare on 8.1, where every fix below already works. Re-verify against
`main` before acting — content here changes, and one 8.1 feature has already been reverted.

The theme is cleanup: 8.1's deprecations become removals, minimum versions rise across the
board (Ruby, SQLite, PostgreSQL, libvips), and CSRF protection moves toward the
`Sec-Fetch-Site` header.

### HIGH Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 1 | **Ruby 3.3.1+ required** | `required_ruby_version` on `main` is `>= 3.3.1`, up from `>= 3.2.0` in 8.0/8.1. Apps on Ruby 3.2 cannot move past 8.1. | `Gemfile`, `.ruby-version`, `Dockerfile`, CI configuration | Upgrade Ruby to 3.3.1 minimum (3.4 recommended) **while still on Rails 8.1**, and get a green suite there, before touching the Rails version. Debugging a Ruby bump and a Rails bump at once is how upgrades stall. |
| 2 | **Active Record 6.1 marshalling format removed** | If the app still uses `active_record.marshalling_format_version = 6.1` — which happens implicitly when `config.load_defaults` is absent or set to 6.1 or lower — cached Active Record objects written in the old format become unreadable. | `config/application.rb`, `config/initializers/new_framework_defaults_*.rb`, cache stores | **Must be done before upgrading.** Set `config.active_record.marshalling_format_version = 7.1` on 8.1, deploy, then flush or let expire every cache holding marshalled AR objects. Only then upgrade. |
| 3 | **Negative enum scopes now include `nil` records** | `Book.not_published` previously returned only records with a non-nil, non-published status. It now also returns records where the enum column is `nil`. Silent result-set change — no error, just more rows. | `app/models/**/*.rb`, `app/controllers/**/*.rb`, anywhere a `not_*` enum scope is used | Audit every `not_<value>` enum scope usage. Where `nil` should stay excluded, add `.where.not(status: nil)` explicitly. Pay particular attention to scopes feeding deletion, billing, or notification logic. |
| 4 | **`raise_on_missing_required_finder_order_columns` config removed** | The 8.1 escape hatch is gone; order-dependent finders on unordered relations always raise `ActiveRecord::MissingRequiredOrderError`. | `config/application.rb`, `app/**/*.rb`, `test/**/*.rb`, `spec/**/*.rb` | Finish the work from 8.0 → 8.1 HIGH #1 while on 8.1, then delete the config line. |
| 5 | **Built-in Sidekiq ActiveJob adapter removed** | `config.active_job.queue_adapter = :sidekiq` no longer resolves to a Rails-supplied adapter. Deprecated in 8.1, removed here. | `config/application.rb`, `config/environments/*.rb`, `Gemfile` | Upgrade to `sidekiq >= 7.3.3`, which registers its own adapter. Do this on 8.1 — it also clears the 8.1 deprecation warning. |
| 6 | **Database minimums raised: SQLite 3.35.0, PostgreSQL 10.0** | SQLite 3.35.0 introduced `RETURNING`, which the adapter has relied on since 7.1 for reading auto-populated columns after `INSERT`. PostgreSQL below 10.0 is no longer supported; `supports_pgcrypto_uuid?` is deprecated because `gen_random_uuid()` has shipped since PG 9.4. | `Dockerfile`, `docker-compose.yml`, CI service definitions, production database | Check `sqlite3 --version` and `SELECT version()` on every environment — CI images and developer laptops drift behind production. Upgrade before the Rails bump. |
| 7 | **libvips unfuzzed loaders disabled (also in 8.1.3.1)** | Requires libvips `>= 8.13` and ruby-vips `>= 2.2.1`. Rails raises at boot below those versions. Variant transformation of BMP, ICO, and PSD raises. | System libvips, `Gemfile.lock`, `variable_content_types` config | Already required if you are on 8.1.3.1+. See 8.0 → 8.1 HIGH #3. |

### MEDIUM Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 8 | **Alphabetical `schema.rb` column sorting reverted** | 8.1's alphabetical column ordering is reverted on `main` because it "creates improper production tables when using `db:prepare`". Column order returns to creation order. | `db/schema.rb` | Expect another large, mostly-noise `schema.rb` diff. Regenerate in a dedicated commit. If you switched to `structure.sql` because of the 8.1 change, you can stay there — nothing forces a move back. |
| 9 | **`protect_from_forgery` without a strategy deprecated** | Calling `protect_from_forgery` with no `:with` option warns. The default changes from `:null_session` to `:exception` under `load_defaults 8.2`. Apps that silently relied on `:null_session` will start raising `ActionController::InvalidCrossOriginRequest`. | `app/controllers/application_controller.rb`, `app/controllers/**/*.rb` | Make the strategy explicit at every call site, or set `config.action_controller.default_protect_from_forgery_with`. Decide deliberately: `:exception` is correct for HTML apps; API endpoints relying on `:null_session` need it spelled out. |
| 10 | **`Sec-Fetch-Site` header CSRF strategy** | New `config.action_controller.forgery_protection_verification_strategy`. `:header_only` rejects requests lacking a same-origin/same-site `Sec-Fetch-Site` header, with no authenticity-token fallback. `:header_or_legacy_token` (the pre-8.2 default) checks the header first and falls back to tokens, logging the fallback. | `config/application.rb`, `config/environments/*.rb` | Run on `:header_or_legacy_token` first and watch the fallback logs. Only move to `:header_only` once the logs are quiet — old browsers and non-browser clients have no `Sec-Fetch-Site` header and will be rejected outright. |
| 11 | **More built-in ActiveJob adapters deprecated** | `resque`, `delayed_job`, `backburner`, `sneakers`, and `queue_classic` built-in adapters are all deprecated, following the Sidekiq/SuckerPunch pattern. | `config/application.rb`, `config/environments/*.rb`, `Gemfile` | Upgrade each gem to a version shipping its own adapter (`resque >= 3.0`, `delayed_job >= 4.2.0`). For gems with no maintained adapter, plan a move to Solid Queue or GoodJob. |
| 12 | **`ActiveSupport::Multibyte::Chars` removed; `require_dependency` deprecated** | `Multibyte::Chars` (deprecated in 8.1) is now removed. `require_dependency` is deprecated with removal targeted at Rails 9.0 — it has been a no-op under Zeitwerk for years. | `app/**/*.rb`, `lib/**/*.rb` | Delete every remaining `.mb_chars` call and every `require_dependency` call. Under Zeitwerk, `require_dependency` does nothing useful. |
| 13 | **`RedisCacheStore` reimplemented on `redis-client`** | Now depends on `redis-client >= 0.28.0` instead of `redis >= 4.0.1`. `ActiveSupport::Cache::RedisCacheStore::DEFAULT_REDIS_OPTIONS` is deprecated. Custom connection setup passing `redis` gem objects or options may not carry over. | `Gemfile`, `config/environments/*.rb`, `config/initializers/cache.rb` | Add `redis-client` to the Gemfile. Review any custom `redis:` connection blocks or option hashes passed to the cache store. Replace `DEFAULT_REDIS_OPTIONS` references. |
| 14 | **Active Storage: ImageProcessing 2.0 and processing option changes** | ImageProcessing 2.0 requires `ruby-vips` or `mini_magick` to be declared **explicitly** in your Gemfile — it no longer pulls one in. `preprocessed: true` is deprecated in favor of `process: :immediately`. New `config.active_storage.analyze` (`:immediately` / `:later` / `:lazily`) makes attachment metadata available during validation. | `Gemfile`, `app/models/**/*.rb` | Add `gem "ruby-vips"` (or `mini_magick`) explicitly. Replace `preprocessed: true` with `process: :immediately`. `analyze: :immediately` is the new default — it moves metadata extraction before validation, which changes timing for large uploads. |
| 15 | **Adapter option deprecations targeting Rails 9.0** | MySQL `strict` in `database.yml` is deprecated (use `variables: { sql_mode: "..." }`). PostgreSQL `schema_order` is deprecated (use `schema_search_path`). PostgreSQL `insert_returning` / `use_insert_returning?` are deprecated (use `prefetch_primary_key?`). `Column#auto_populated?` becomes `auto_populated_on_insert?`. `write_attribute(:id, value)` for primary keys is deprecated in favor of `#id=`. | `config/database.yml`, `app/models/**/*.rb`, `lib/**/*.rb` | Mechanical renames. Do them as warnings appear — all have Rails 9.0 removal targets, so there is time, but no reason to wait. |
| 16 | **Action View: ERB handler is private API; `safe_join` drops the `$,` fallback** | `ActionView::Template::Handlers::ERB` is now private API — configure via `ActionView::Base` instead. `safe_join` no longer falls back to the `$,` global when no separator is passed. Registering a `DependencyTracker` after initialization will raise `FrozenError` in a future version. | `config/initializers/**/*.rb`, `app/helpers/**/*.rb`, `lib/**/*.rb` | Move ERB configuration (trim mode, escape handling) onto `ActionView::Base`. Pass separators to `safe_join` explicitly. Move `DependencyTracker.register_tracker` calls into an initializer that runs before the app is initialized. |
| 17 | **Action Pack internal constants deprecated** | `Mime::SET`, `Mime::LOOKUP`, and `Mime::EXTENSION_LOOKUP` are deprecated (use `Mime.symbols`, `Mime::Type.lookup`, `Mime::Type.lookup_by_extension`). `ActionController::Renderers::RENDERERS` is deprecated (use `add_renderer` / `remove_renderer` / `Renderers.all`). `ActionDispatch::Cookies::HTTP_HEADER` is deprecated (use `Rack::SET_COOKIE`). Registering MIME types after initialization will raise `FrozenError`. Middleware `#args` no longer includes keyword arguments — inspect `#kwargs` separately. | `config/initializers/mime_types.rb`, `config/initializers/**/*.rb`, `lib/**/*.rb`, custom middleware | Move all `Mime::Type.register` calls into `config/initializers/mime_types.rb` so they run before the registry freezes. Swap the deprecated constants for the public methods. Update middleware-introspection code to read `#kwargs`. |
| 18 | **MySQL parallel test databases reset with DELETE, not TRUNCATE** | Auto-increment counters no longer reset between parallel test runs, and `SKIP_TEST_DATABASE_TRUNCATE` has no effect. Tests asserting on specific record ids will fail. | `test/**/*.rb`, `spec/**/*.rb`, CI configuration | Remove `SKIP_TEST_DATABASE_TRUNCATE` from CI. Fix tests that assert on literal id values — they were always fragile. |
| 19 | **New framework defaults worth staging** | `strict_accept_header = true` (a request with `Accept: application/json, */*` now returns JSON instead of always defaulting to HTML). `raise_on_invalid_time_zone_parse = true` (`TimeZone#parse("foobar")` raises instead of returning `nil`). `postgresql_adapter_decode_bytea` / `decode_money` (raw queries return binary Strings and BigDecimals rather than UTF-8 Strings). `X-XSS-Protection` dropped from `default_headers`. `rescue_from_event_backtrace = :array`. | `config/initializers/new_framework_defaults_8_2.rb` | `strict_accept_header` is the risky one — it can flip the format of existing endpoints for clients sending `*/*`. Enable it alone and exercise every content-negotiated route. `raise_on_invalid_time_zone_parse` will surface user-input parsing that silently returned `nil`. |

### LOW Priority

| # | Change | Impact | Files Affected | Action Required |
|---|---|---|---|---|
| 20 | **Frozen string literals in generated apps** | New apps get a `config/bootsnap.rb` enabling frozen string literals, with `.rubocop.yml` configured to match. Not applied to existing apps on upgrade. | `config/bootsnap.rb`, `.rubocop.yml` | Optional adoption. If you opt in, expect `FrozenError` from any code mutating string literals in place. |
| 21 | **Console behavior changes** | Query cache is now **off** by default in `bin/rails console` (pass `--query-cache` to enable). The console is wrapped with the executor by default (disable with `-w` / `--skip_executor`). A startup banner shows the Rails logo, version, and rotating tips (`RAILS_TIPS=false` to hide). | Developer workflow, console scripts | No action required. Console one-liners that relied on implicit query caching may run more queries. |
| 22 | **`Rails.app` and configuration accessors** | `Rails.app` is a new alias for `Rails.application`. New `Rails.app.creds` (combined ENV + encrypted credentials + `.env`), `Rails.app.envs`, `Rails.app.dotenvs`, and `Rails.app.revision` (from `ENV["REVISION"]`, a `REVISION` file, or git). | `config/**/*.rb`, `app/**/*.rb` | Optional adoption. `Rails.app.revision` is genuinely useful for error-reporter release tagging. |
| 23 | **`bin/rails query` command** | New read-only database query command supporting Active Record expressions, raw SQL, JSON output, and schema introspection. | Developer workflow | Optional. Useful in production consoles where you want a read-only guarantee. |
| 24 | **Action Cable configuration namespace move** | `ActionCable::Server::Configuration` moved to `ActionCable::Configuration`. The old constant remains as an alias. Origin checking now respects `X-Forwarded-Host` behind reverse proxies. | `config/initializers/action_cable.rb`, `config/cable.yml` | No action required. The `X-Forwarded-Host` fix may resolve existing origin-check failures behind a proxy. |
| 25 | **Action Mailbox ingress hardening; `Mail::Address.wrap` deprecated** | Malformed Mailgun, Postmark, SendGrid, and Mandrill payloads now return `422 Unprocessable Content` (and `401` for malformed Mailgun signatures) instead of raising. `Mail::Address.wrap` is deprecated as unused. | `app/mailboxes/**/*.rb`, ingress monitoring | No action required. Error-rate dashboards will show 4xx where they previously showed 5xx — update alert thresholds. |

---

## Cumulative Impact Analysis

### Full Journey: Rails 5.2 → 8.1

Upgrading across all versions involves cumulative exposure to all the changes above. The total effort is substantially more than the sum of individual hops because some changes interact.

#### Top 12 Most Impactful Changes (by breadth of codebase affected)

| Rank | Change | Version | Why It Is High Impact |
|---|---|---|---|
| 1 | Transaction-aware jobs | 7.2 | Silent behavior change. Jobs that previously ran before a transaction committed now run after. Race conditions disappear, but timing-sensitive code breaks silently. |
| 2 | Sprockets → Propshaft | 8.0 | Complete asset pipeline replacement. Apps with complex Sprockets manifests require full rewrite of asset loading strategy. |
| 3 | Zeitwerk autoloader | 6.0 | Every file in the app must follow strict naming conventions. Large legacy codebases with informal naming patterns require widespread renaming. |
| 4 | `MissingRequiredOrderError` on unordered finders | 8.1 | `.first` / `.last` on an unordered relation is one of the most common patterns in Rails code and test suites. Surfaces as a broad wave of failures rather than a single error. |
| 5 | cache_classes → enable_reloading (inverted boolean) | 7.1 | Every environment file must be updated. The inverted boolean means a copy-paste error produces the opposite of the intended behavior. Easy to overlook in a large diff. |
| 6 | Multi-database config restructure | 8.0 | `config/database.yml` structure changes significantly for apps adopting Solid gems. |
| 7 | show_exceptions changed to symbol | 7.2 | Breaks boot in all three environment configs if not updated. Error is clear but affects multiple files. |
| 8 | ActiveRecord::Base.connection deprecated | 7.2 | This pattern appears in many places: initializers, lib code, custom middleware, Rake tasks. |
| 9 | Webpacker → Hotwire/Turbo/ImportMaps | 7.0 | Complete JavaScript pipeline replacement. All Turbolinks event handlers, data attributes, and JavaScript events must be updated. |
| 10 | Rails.application.secrets removed | 7.2 | Complete API removal. Every reference to secrets must be migrated to credentials. |
| 11 | libvips unfuzzed loaders disabled (CVE-2026-66066) | 8.1.3.1 | Hard boot failure below libvips 8.13, plus BMP/ICO/PSD variants start raising. Infrastructure work, not code work — easy to miss until deploy. |
| 12 | Negative enum scopes include `nil` | 8.2 | Silent result-set change with no error. Extra rows flow into whatever the scope feeds — deletion, billing, notifications. |

#### Hardest Single-Hop Upgrades

1. **7.2 → 8.0** (Very Hard): Asset pipeline replacement, Solid gems defaults, multi-database restructure all at once.
2. **6.1 → 7.0** (Hard): JavaScript pipeline replacement (Webpacker → Hotwire), `legacy_connection_handling` removal, Ruby 2.7 requirement.
3. **5.2 → 6.0** (Hard): Zeitwerk autoloader requires renaming files and removing `require_dependency` throughout the codebase.

The 8.x hops are each Medium: individually manageable, but 8.0 → 8.1 is routinely
under-estimated because the official upgrading guide lists only one item for it.

#### Recommended Multi-Hop Strategy

For apps on Rails 5.2 upgrading to 8.1:

```
5.2 → 6.0  (address Zeitwerk, remove require_dependency, fix method removals)
6.0 → 6.1  (fix errors[] usage, verify file uploads)
6.1 → 7.0  (migrate JS pipeline, address Ruby 2.7 requirement)
7.0 → 7.1  (fix cache_classes inversion, lib/ autoloading)
7.1 → 7.2  (fix secrets, show_exceptions, transaction job behavior)
7.2 → 8.0  (migrate asset pipeline, evaluate Solid gems)
8.0 → 8.1  (fix unordered finders, path-relative redirects, libvips/CVE, rename pool)
```

Land on the newest patch of the target series (currently `8.1.3.1`), not the `.0`.

Each hop should be: upgrade gem → run `rails app:update` (reviewing each change) → run test suite → fix deprecation warnings → commit before proceeding to next hop.

#### Preparing for 8.2 while on 8.1

Rails 8.2 is unreleased, but its whole HIGH-priority list can be cleared from 8.1:

```
On Rails 8.1, in this order:
1. Bump Ruby to >= 3.3.1                          (blocks everything else)
2. Set marshalling_format_version = 7.1, flush caches
3. Upgrade sidekiq to >= 7.3.3
4. Upgrade SQLite to >= 3.35.0, PostgreSQL to >= 10.0 (all environments, incl. CI)
5. Upgrade libvips to >= 8.13, ruby-vips to >= 2.2.1
6. Fix every unordered .first/.last, then drop the escape-hatch config
7. Audit not_<value> enum scopes for nil handling
```

Doing this work on 8.1 means the eventual 8.2 bump is a version-number change plus a
`schema.rb` regeneration, not a project.

---

## By-Symptom Quick Search Index

Use this section when you see a specific error or symptom and need to find the relevant change quickly.

### "My tests are failing with..."

| Symptom | Relevant Change | Version | Fix |
|---|---|---|---|
| `show_exceptions` error or invalid value | Boolean → symbol | 7.2 | Change `true`/`false` to `:all`/`:none` |
| `params == some_hash` returns false | Parameters ≠ Hash | 7.2 | Use `params.to_h == some_hash` |
| `connection` deprecated warning | `Base.connection` deprecated | 7.2 | Use `with_connection` or `lease_connection` |
| `NameError: uninitialized constant` after rename | Zeitwerk naming | 6.0 | File name must match constant name exactly |
| `errors[:attr]` returns objects not strings | Error objects | 6.1 | Call `.message` on each error or use `full_messages_for` |
| `cache_classes` unknown configuration key | Config key renamed | 7.1 | Rename to `enable_reloading` (and invert boolean) |
| `fixture_path` deprecation warning | Singular → plural | 7.2 | Use `fixture_paths` as an array |
| `args:` unknown keyword in mailer test | Test syntax change | 7.2 | Rename `args:` to `params:` |
| `serialize :column` raises error | Serialize requires type | 7.2 | Add `type: Array` or `coder: JSON` |
| `ActiveRecord::MissingRequiredOrderError` | Unordered `#first`/`#last` | 8.1 | Add an explicit `order`, or set `implicit_order_column` on the model |
| `UnsafeRedirectError` on a relative redirect | Path-relative redirects raise | 8.1 | Give the path a leading `/`, or stage via `action_on_path_relative_redirect = :log` |
| Rendered JSON contains raw `<`, `>`, `&` | `escape_json_responses = false` | 8.1 | Expected. Only a problem if JSON is interpolated into a `<script>` tag |
| HTML assertions fail on missing `autocomplete="off"` | `remove_hidden_field_autocomplete` | 8.1 | Update the fixture; the attribute is intentionally gone |
| Mailer/job test fails on a literal record id | MySQL parallel DB reset uses DELETE | 8.2 | Auto-increment no longer resets — stop asserting on literal ids |
| A `not_<value>` enum scope returns extra rows | Negative enum scopes include `nil` | 8.2 | Add `.where.not(column: nil)` where `nil` should stay excluded |

### "My app raises on boot with..."

| Symptom | Relevant Change | Version | Fix |
|---|---|---|---|
| `NoMethodError: update_attributes` | Method removed | 6.0 | Replace with `update` |
| `NoMethodError: before_filter` | Method removed | 6.0 | Replace with `before_action` |
| `NoMethodError: require_dependency` | Method removed | 6.0 | Remove the call; Zeitwerk autoloads it |
| `NoMethodError: secrets` | `secrets` removed | 7.2 | Migrate to `credentials` |
| `ArgumentError: render nothing: true` | Option removed | 6.0 | Use `head :ok` |
| `legacy_connection_handling` error | Option removed | 7.0 | Remove the config key |
| Boot fails complaining about libvips version | Unfuzzed loaders cannot be blocked below libvips 8.13 | 8.1.3.1 | Upgrade system libvips to `>= 8.13`. No config workaround exists below that version |
| `NoMethodError` on a `:sucker_punch` queue adapter | Built-in adapter removed | 8.1 | Upgrade to `sucker_punch >= 3.2` |
| `NoMethodError` on a `:sidekiq` queue adapter | Built-in adapter removed | 8.2 | Upgrade to `sidekiq >= 7.3.3` (do this on 8.1 to clear the warning early) |
| `NameError: ActiveSupport::Multibyte::Chars` | Class removed | 8.2 | Delete the `.mb_chars` call |
| `FrozenError` from `Mime::Type.register` | MIME registry frozen after init | 8.2 | Move registration into `config/initializers/mime_types.rb` |
| Unreadable/garbled cached Active Record objects | 6.1 marshalling format removed | 8.2 | Set `marshalling_format_version = 7.1` and flush caches **before** upgrading |
| Ruby version error on `bundle install` | Ruby floor raised to 3.3.1 | 8.2 | Bump Ruby while still on 8.1 |

### "I can't deploy because..."

| Symptom | Relevant Change | Version | Fix |
|---|---|---|---|
| SSL redirect loop | `force_ssl`/`assume_ssl` misconfigured | 7.1, 8.0, 8.1 | Set `force_ssl` and `assume_ssl` explicitly based on your SSL termination topology |
| Jobs not processing / running too early | Transaction-aware jobs | 7.2 | Jobs inside transactions now run post-commit; review all `perform_later` inside `transaction` blocks |
| Database connection errors in production | `database.yml` changes | 7.2, 8.0, 8.1 | Review `database.yml` structure after each `rails app:update` |
| Assets 404 in production | Propshaft migration incomplete | 8.0 | Complete migration from Sprockets; remove `//= require` directives |
| Webpacker compile errors | Webpacker removed | 7.0 | Migrate to Import Maps or jsbundling-rails |
| ActiveStorage files not loading | Azure service removed | 8.1 | Migrate to S3, GCS, or Disk service |
| SuckerPunch jobs not enqueuing | Built-in adapter removed | 8.1 | Upgrade to `sucker_punch >= 3.2` |
| Sidekiq jobs not enqueuing | Built-in adapter removed | 8.2 | Upgrade to `sidekiq >= 7.3.3` |
| App will not boot after a security patch | libvips `< 8.13` cannot block unfuzzed loaders | 8.1.3.1 | Upgrade system libvips (rebuild the container image — this is not a gem) |
| BMP / ICO / PSD variants raise | Unfuzzed libvips loaders disabled | 8.1.3.1 | Remove those types from `variable_content_types` and provide a fallback |
| Ruby version rejected at deploy | Ruby floor raised to 3.3.1 | 8.2 | Bump Ruby, `.ruby-version`, Dockerfile, and CI together |
| SQLite or PostgreSQL version rejected | Minimums raised to 3.35.0 / 10.0 | 8.2 | Upgrade the database in every environment, CI included |

### "I see deprecation warnings about..."

| Warning Text | Relevant Change | Version | Fix |
|---|---|---|---|
| `cache_classes` | Config renamed | 7.1 | Rename to `enable_reloading` (invert boolean) |
| `preview_path` | Singular → plural | 7.1 | Use `preview_paths` as array |
| `fixture_path` | Singular → plural | 7.2 | Use `fixture_paths` as array |
| `ActiveRecord::Base.connection` | Method deprecated | 7.2 | Use `with_connection` |
| `serialize :column` without type | Type required | 7.2 | Add `type:` or `coder:` |
| `query_constraints` | Deprecated | 7.2 | Use `foreign_key` |
| `unsigned: true` in migration | Deprecated | 8.1 | Use a check constraint instead |
| Unordered finder / missing order columns | Behavior deprecated ahead of 8.2 | 8.1 | Add an explicit `order` or `implicit_order_column` |
| `String#mb_chars` / `Multibyte::Chars` | Deprecated 8.1, removed 8.2 | 8.1 | Delete the call — plain String methods are encoding-aware |
| `to_time_preserves_timezone` | Config deprecated | 8.1 | Set `:zone`, verify, then remove the line |
| `ActiveSupport::Configurable` | Deprecated | 8.1 | Use `class_attribute` or a plain config object |
| `signed_id_verifier_secret` | Deprecated | 8.1 | Use `Rails.application.message_verifiers` |
| `insert_all`/`upsert_all` on unpersisted association | Deprecated | 8.1 | Persist the owner first, or insert on the class with explicit FKs |
| `WITH` / `DISTINCT` with `update_all` | Deprecated | 8.1 | `pluck(:id)` first, then `where(id: ids).update_all` |
| Custom job serializer `#klass` is private | Deprecated | 8.1 | Move `def klass` above `private` |
| `to_trix_html` / `TrixAttachment` | Deprecated | 8.1 | Use `to_s` / the editor-agnostic Action Text API |
| `render_in` without keyword args | Deprecated | 8.1 | `def render_in(view_context, **options, &block)` |
| `protect_from_forgery` without a strategy | Deprecated | 8.2 | Pass `with:` explicitly, or set `default_protect_from_forgery_with` |
| `require_dependency` | Deprecated, removal in 9.0 | 8.2 | Delete it — it is a no-op under Zeitwerk |
| MySQL `strict` in database.yml | Deprecated, removal in 9.0 | 8.2 | Use `variables: { sql_mode: "..." }` |
| PostgreSQL `schema_order` | Deprecated, removal in 9.0 | 8.2 | Use `schema_search_path` |
| `Mime::SET` / `LOOKUP` / `EXTENSION_LOOKUP` | Deprecated | 8.2 | Use `Mime.symbols` / `Mime::Type.lookup` / `lookup_by_extension` |
| `write_attribute(:id, value)` | Deprecated | 8.2 | Use the model's `#id=` |
| `preprocessed: true` on an attachment | Deprecated | 8.2 | Use `process: :immediately` |

Note on `pool:` in `database.yml`: Rails 8.1 renamed `pool` to `max_connections` alongside
the new `keepalive`, `max_age`, and `min_connections` options. Default behavior is unchanged
and `pool:` continues to work — adopt the new name for consistency, but it is not a break.

---

## Attribution

Based on work by OmbuLabs.ai / FastRuby.io (MIT) and Mario Alberto Chavez Cardenas (MIT).

Official release notes: https://guides.rubyonrails.org/upgrading_ruby_on_rails.html
