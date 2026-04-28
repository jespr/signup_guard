# SignupGuard

[![CI](https://github.com/jespr/signup_guard/actions/workflows/ci.yml/badge.svg)](https://github.com/jespr/signup_guard/actions/workflows/ci.yml)

Layered signup-time + post-signup abuse detection for Rails apps.
Captures every signup attempt with rich signals (honeypot, fingerprint, MX,
Turnstile, IP reputation, fingerprint reuse, IP burst), composes them into
a risk score, and optionally enforces outcomes (allow / review / block) at
the controller layer.

> **Status**: alpha. Extracted from a working production app; the API is
> still moving. Ships with sensible defaults for Devise + Postgres but is
> agnostic to your auth setup.

## Install

```ruby
# Gemfile
gem "signup_guard"
```

```sh
bundle install
bin/rails generate signup_guard:install
bin/rails db:migrate
bin/rails signup_guard:refresh_disposable_domains
```

The install generator creates `config/initializers/signup_guard.rb`, copies the
gem's `signup_guard_signals` table migration into your `db/migrate/`, and adds
a `requires_review` boolean column (with a partial index on the truthy case)
to your `users` table.

**Generator options** (sensible defaults — you usually don't need any of these):

```sh
bin/rails generate signup_guard:install --user-class=Account
bin/rails generate signup_guard:install --requires-review-attribute=needs_review
bin/rails generate signup_guard:install --skip-user-migration
bin/rails generate signup_guard:install --skip-initializer
```

The last setup step (`refresh_disposable_domains`) pulls the latest
[disposable-email-domains](https://github.com/disposable-email-domains/disposable-email-domains)
blocklist to the path configured by `c.disposable_domains_path` (default:
inside the gem). Re-run weekly via cron / a recurring job to keep it current:

```ruby
# config/recurring.yml (Solid Queue) or wherever you schedule things
signup_guard_refresh:
  class: "ProcessAtCommand"  # or your scheduler's equivalent
  schedule: "every Sunday at 3am"
  command: "Rake::Task['signup_guard:refresh_disposable_domains'].invoke"
```

## Configure

The install generator writes `config/initializers/signup_guard.rb` with all
options commented out — sensible defaults work for a Devise + encrypted-credentials
setup. Uncomment what you need to override:

```ruby
SignupGuard.configure do |c|
  c.user_class = "User"
  c.requires_review_attribute = :requires_review

  # How to find the email + the user inside your signup controller
  # c.email_param   = ->(params) { params.dig(:user, :email) }
  # c.user_resolver = ->(controller) { controller.send(:resource) }  # Devise default

  # Skip enforcement entirely for trusted flows
  # c.bypass_signup = ->(controller) { controller.params[:invite].present? }

  # Override individual weights without forking
  # c.scorer_weights[:tor_exit] = 75

  # Credentials: defaults read Rails.application.credentials.dig(env, ...)
  # Override if you store keys elsewhere.
  # c.turnstile_credentials = -> { { site_key: ENV["TURNSTILE_SITE_KEY"], secret: ENV["TURNSTILE_SECRET"] } }

  # Where to send swallowed exceptions (default: no-op)
  # c.error_reporter = ->(e) { Honeybadger.notify(e) }
end
```

## Wire into your signup controller

```ruby
class Users::RegistrationsController < Devise::RegistrationsController
  include SignupGuard::CapturesSignals

  # Optional: hook into invisible_captcha to recover gem-rejected signals
  invisible_captcha only: [:create],
    on_spam: :record_invisible_captcha_spam,
    on_timestamp_spam: :record_invisible_captcha_spam

  private

  def record_invisible_captcha_spam
    capture_signup_signal(overrides: { honeypot_triggered: true })
    redirect_to new_user_session_path, alert: "..."
  end
end
```

## Gate downstream actions for flagged users

```ruby
class FormsController < ApplicationController
  include SignupGuard::BlocksPendingReview
end
```

## Frontend

The install generator copies a Stimulus controller to
`app/javascript/controllers/signup_timer_controller.js` (override the path with
`--stimulus-path=...`, or skip it with `--skip-stimulus`).

Add the FingerprintJS dependency to your frontend bundler:

```sh
yarn add @fingerprintjs/fingerprintjs           # esbuild / vite / jsbundling
bin/importmap pin @fingerprintjs/fingerprintjs  # importmap
```

Then add the honeypot + timer + fingerprint hidden fields to your signup form:

```erb
<%= form_with model: @user, data: { controller: "signup-timer" } do |f| %>
  <div class="sr-only" aria-hidden="true">
    <input type="text" name="website" tabindex="-1" autocomplete="off" />
  </div>
  <%= hidden_field_tag :form_rendered_at, nil, data: { signup_timer_target: "renderedAt" } %>
  <%= hidden_field_tag :fingerprint, nil, data: { signup_timer_target: "fingerprint" } %>

  <% if SignupGuard::Turnstile.configured? %>
    <div class="cf-turnstile" data-sitekey="<%= SignupGuard::Turnstile.site_key %>"></div>
    <%= javascript_include_tag "https://challenges.cloudflare.com/turnstile/v0/api.js", async: true, defer: true %>
  <% end %>

  <%# ...your fields... %>
<% end %>
```

## Risk score reference

| Signal | Default weight |
|---|---|
| Honeypot triggered | 100 |
| Turnstile failed | 60 |
| Tor exit node | 50 |
| Disposable email | 40 |
| Fingerprint reused (5+/7d) | 40 |
| High IP risk (>75) | 40 |
| Form submitted in <1s | 35 |
| MX invalid | 30 |
| Datacenter IP | 30 |
| IP burst (3+/24h) | 25 |
| Form submitted 1-3s | 15 |
| No fingerprint | 10 |
| Freemail + 3+ digits | 10 |

Levels: `low` 0–29, `medium` 30–59, `high` 60–99, `block` 100+.

## Enforcement

Set in credentials when you're ready to flip:

```yaml
production:
  signup_enforcement:
    enabled: true
```

| Level | Outcome |
|---|---|
| `low` | Normal signup |
| `medium` | Normal signup (host app may opt to require email verification) |
| `high` | User created with `requires_review: true`. Forms / API keys gated. |
| `block` | No user created. Same redirect as `high` to avoid leaking the block. |

Until the credential is set, `SignupGuard::Enforcement.enabled?` returns false
and every outcome is `:allow`. Safe to ship behind the flag.

## What's not in scope

- ML / anomaly detection (use the captured data to train your own)
- Account-level abuse detection (this is signup-time only)
- OAuth signup paths (the controller concern targets form-based signup;
  hook the OAuth callbacks separately if you need it)

## License

MIT
