# Troubleshooting

## Test Suite Failures After Upgrade

**"NoMethodError: undefined method 'update_attributes'"**
- Cause: Removed in Rails 6.0
- Fix: `grep -r "update_attributes" app/ lib/` and replace with `update`

**"ArgumentError: wrong number of arguments (given 1, expected 0)"** on cache
- Cause: Cache format change in Rails 7.1 or 8.0 load_defaults
- Fix: Clear cache: `rails cache:clear`. If in production, coordinate cache clear with deploy.

**"ActionController::Parameters does not respond to to_h"** or params comparison error
- Cause: Rails 7.2 removed `params == hash`
- Fix: Use `params.to_h == hash` or `params.permit(...) == hash`

**"ActiveRecord::ConnectionNotEstablished"**
- Cause: Direct `ActiveRecord::Base.connection` usage removed in 7.2
- Fix: Wrap in `ActiveRecord::Base.with_connection { |conn| ... }`

**Jobs not running after transaction**
- Cause: Rails 7.2 transaction-aware job enqueuing — jobs wait for transaction commit
- Fix: Expected behavior. If you need immediate execution, use `perform_now`. Test your transaction boundaries.

**"NameError: wrong constant name" or autoload errors**
- Cause: Zeitwerk naming mismatch (Rails 6.0)
- Fix: Run `rails zeitwerk:check` to identify problematic files. File `app/models/my_model.rb` must define `MyModel`, not `My_Model`.

**"show_exceptions must be a Symbol"**
- Cause: Rails 7.2 — `show_exceptions` no longer accepts booleans
- Fix: `config.action_dispatch.show_exceptions = :all` (was `true`) or `:none` (was `false`)

**"ActiveRecord::MissingRequiredOrderError"**
- Cause: Rails 8.1 `raise_on_missing_required_finder_order_columns`. `#first`/`#last`/`#second` on a relation with no `order`, where the model has no `implicit_order_column`, `query_constraints`, or `primary_key` to fall back on
- Fix: Add an explicit `order`, or set `implicit_order_column` on the model. Models with a normal primary key are unaffected — if this fires, the model genuinely has no deterministic ordering
- Note: This lands as many failures at once, not one. Enable the flag alone in `new_framework_defaults_8_1.rb` and treat the failure list as your work queue

**"ActionController::Redirecting::UnsafeRedirectError"**
- Cause: Rails 8.1 `action_on_path_relative_redirect = :raise`. `redirect_to "example.com"` has no leading slash
- Fix: Add the leading `/`. To stage it, set `:log` (the previous default) or `:notify` and clear the logs first

**Rendered JSON suddenly contains raw `<`, `>`, `&`**
- Cause: Rails 8.1 `escape_json_responses = false`
- Fix: Expected and safe for JSON consumers. Only a problem if you interpolate rendered JSON into an HTML `<script>` block — fix those sites, or set `escape_json_responses = true` explicitly

**HTML assertions fail on a missing `autocomplete="off"`**
- Cause: Rails 8.1 `remove_hidden_field_autocomplete = true`
- Fix: Update the fixture. The attribute is intentionally gone from `form_tag`, `token_tag`, `method_tag`, and `button_to` hidden fields

**"NoMethodError" on a `:sucker_punch` queue adapter**
- Cause: Rails 8.1 removed the built-in SuckerPunch adapter
- Fix: `gem 'sucker_punch', '>= 3.2'` — it ships its own adapter

**Deprecation warning about the `:sidekiq` adapter**
- Cause: Rails 8.1 deprecated the built-in Sidekiq adapter. It still works on 8.1; removal is in 8.2
- Fix: `gem 'sidekiq', '>= 7.3.3'`. No config change needed — the gem registers the adapter

**Huge unexplained `db/schema.rb` diff after the first migrate**
- Cause: Rails 8.1 sorts table columns alphabetically in `schema.rb`
- Fix: Expected. Commit the regeneration on its own so it does not bury real changes. Note that this is reverted in 8.2, so a second large diff is coming — or switch to `structure.sql` if exact column order matters

## Active Storage / libvips (CVE-2026-66066)

**App fails to boot complaining about the libvips version**
- Cause: From 8.1.3.1 / 8.0.5.1 / 7.2.3.2, Active Storage disables libvips "unfuzzed" loaders. libvips `< 8.13` cannot block them at all, so Rails refuses to boot rather than run unsecurable
- Fix: Upgrade **system** libvips to `>= 8.13` — this is not a gem, so update the Dockerfile or base image, not the Gemfile. Verify with `vips --version`
- No workaround exists below 8.13 other than removing libvips entirely. Apps that declared `ruby-vips` only for image analysis can drop it from the Gemfile

**BMP / ICO / PSD variants raise after upgrading**
- Cause: Those loaders are among the unfuzzed operations now blocked
- Fix: Remove those content types from `variable_content_types` and provide a fallback for existing attachments. There is no way to re-enable them safely

**Want to fix the vulnerability without upgrading Rails**
- Fix: With libvips `>= 8.13` present, set the `VIPS_BLOCK_UNTRUSTED` environment variable (libvips reads it at init). With `ruby-vips >= 2.2.1`, call `Vips.block_untrusted(true)` from an initializer. Both are stopgaps — upgrade Rails
- If the app ran an affected version while accepting untrusted uploads, rotate `secret_key_base`, the master key and everything `credentials.yml.enc` decrypts, Active Storage service credentials, database credentials, and third-party tokens. Rotating `secret_key_base` expires sessions, signed/encrypted cookies, signed global IDs, and Active Storage URLs

## Rails 8.2 Preparation Issues (Unreleased)

**Cached Active Record objects unreadable after upgrading**
- Cause: Rails 8.2 removed the 6.1 marshalling format. Apps that never call `load_defaults`, or call it with 6.1 or lower, are implicitly on it
- Fix: **Before** upgrading, set `config.active_record.marshalling_format_version = 7.1` on 8.1, deploy, then flush or expire every cache holding marshalled AR objects

**A `not_<value>` enum scope returns more rows than before**
- Cause: Rails 8.2 negative enum scopes now include records where the column is `nil`
- Fix: Add `.where.not(column: nil)` where `nil` should stay excluded. Audit scopes feeding deletion, billing, or notification logic first — this change is silent

**"FrozenError" from `Mime::Type.register` or `DependencyTracker.register_tracker`**
- Cause: Rails 8.2 freezes both registries after initialization
- Fix: Move registration into an initializer (`config/initializers/mime_types.rb`) so it runs before the app finishes initializing

**Tests fail on literal record ids under MySQL**
- Cause: Rails 8.2 resets parallel test databases with `DELETE` instead of `TRUNCATE`, so auto-increment counters no longer reset. `SKIP_TEST_DATABASE_TRUNCATE` has no effect
- Fix: Remove the env var from CI and stop asserting on literal ids

**An endpoint starts returning JSON where it used to return HTML**
- Cause: Rails 8.2 `strict_accept_header = true`. A client sending `Accept: application/json, */*` now gets JSON rather than defaulting to HTML
- Fix: Enable the flag alone and exercise every content-negotiated route before shipping

## Asset Pipeline Issues (Rails 8.0)

**Assets returning 404 after upgrade**
- Cause: Incomplete Propshaft migration
- Fix:
  1. Remove `sprockets-rails` from Gemfile, add `propshaft`
  2. Remove `config.assets.*` Sprockets-specific config
  3. Remove `//= require` directives in JS/CSS files (Propshaft uses imports instead)
  4. Run `rails assets:precompile` and check output

**"Sprockets::Error: Asset not found"**
- Cause: Still using Sprockets manifest directives with Propshaft
- Fix: Rewrite asset includes as direct imports

## railsdiff.org API Issues

**WebFetch returns empty or error for GitHub compare URL**
- Cause: GitHub API rate limit (60 req/hour unauthenticated) or network issue
- Fix: Wait and retry, or proceed with static detection patterns in `references/detection-patterns.md`. Note in the report that live config diff was unavailable.

**Version tag not found in railsdiff repo**
- Cause: Very new patch release not yet in the `railsdiff/rails-new-output` repo
- Fix: Use the nearest minor version tag (e.g., `v8.1.0` if `v8.1.1` not found). Or use static references.

**Unexpected diff content**
- Cause: Some patch releases change files that aren't breaking. railsdiff shows ALL changes.
- Fix: Focus on files in `config/environments/`, `config/initializers/`, `config/database.yml`, `Gemfile`. Ignore `package.json`, CSS files unless you're explicitly migrating assets.

## Gem Conflicts

**"Bundler could not find compatible versions"**
- Fix: Run `bundle update rails --conservative`. Check which gem is blocking with `bundle update rails 2>&1 | grep "Conflict"`. See `references/gem-compatibility.md` for required versions.

**Devise not working after upgrade**
- Fix: Check `references/gem-compatibility.md` for required Devise version. Run `bundle update devise`. Check for pending migrations: `rails db:migrate:status`.

**RSpec failures that passed before**
- Cause: Often rspec-rails version incompatibility
- Fix: Upgrade `rspec-rails` to the version in `references/gem-compatibility.md`. Common: `gem 'rspec-rails', '~> 6.0'` for Rails 7+.

## load_defaults Issues

**"Uninitialized constant" after enabling new defaults**
- Cause: Zeitwerk-related change from load_defaults 6.0
- Fix: Run `rails zeitwerk:check` to identify all naming issues. Check `references/load-defaults-guide.md` Tier 3 section.

**Session/cookie errors after bumping load_defaults**
- Cause: `active_support.message_serializer` change (7.1)
- Fix: Do not change message_serializer if you have existing user sessions. Wait for session expiry window, then enable.

**Tests fail only in CI after load_defaults change**
- Cause: Cache format version change — CI may have cached assets/data in old format
- Fix: Clear CI cache, or add explicit cache invalidation step.

## Fetch Changelog Script Issues

**`./scripts/fetch-changelogs.sh: Permission denied`**
- Fix: `chmod +x scripts/fetch-changelogs.sh`

**`curl: command not found`**
- Fix: Install curl: `brew install curl` (macOS) or `apt-get install curl` (Ubuntu)

**No output for a version**
- Cause: That patch version may not exist as a tag in the Rails repo
- Fix: Run `./scripts/fetch-changelogs.sh --list-versions` to see available tags. Use the nearest minor version.

**"does not look like a valid version number" for a security release**
- Cause: Security releases carry a fourth segment (`8.1.3.1`). The script accepts 2-4 segments
- Fix: If this still errors, the script predates the fix — the validation regex should be `^[0-9]+\.[0-9]+(\.[0-9]+){0,2}$`

**Most components return a 3-line section for a security release**
- Cause: Expected. A security release touches one component; the rest get a version-bump stub
- Fix: None. For `8.1.3.1` only `activestorage` has real content — that IS the CVE-2026-66066 fix

**Want the unreleased (next version) changelogs**
- Fix: `./scripts/fetch-changelogs.sh main ./changelogs`. Main's CHANGELOGs contain only entries merged since the last release branch was cut, so they describe the next version (currently 8.2). They have no `## Rails X.Y.Z` headers at all — the file ends with a "Please check X-Y-stable for previous changes" pointer
- Treat everything it returns as provisional. Entries get reverted before release; the alphabetical `schema.rb` sorting from 8.1 is one that already was

## Attribution

Compiled from:
- Mario Alberto Chavez Cardenas (MIT) — troubleshooting reference from rails-upgrade-skill
- OmbuLabs.ai / FastRuby.io (MIT) — common upgrade issues from claude-code_rails-upgrade-skill
- Community knowledge and Rails issue tracker
