# frozen_string_literal: true

SignupGuard.configure do |c|
  c.user_class = "<%= user_class %>"
  c.requires_review_attribute = :<%= requires_review_attribute %>

  # How to find the email + the user inside your signup controller.
  # Defaults assume Devise's nested `user` params and `controller.resource`.
  # c.email_param   = ->(params) { params.dig(:user, :email) }
  # c.user_resolver = ->(controller) { controller.send(:resource) }

  # Skip enforcement entirely for trusted flows (invitations, internal tools, etc).
  # c.bypass_signup = ->(controller) { controller.params[:invite].present? }

  # Override individual scoring weights without forking. See
  # SignupGuard::RiskScorer::DEFAULT_WEIGHTS for the full list.
  # c.scorer_weights[:tor_exit] = 75

  # Where to send swallowed exceptions. Default is no-op.
  # c.error_reporter = ->(e) { Honeybadger.notify(e) }

  # External service credentials. The defaults read from Rails encrypted
  # credentials under the current Rails.env namespace. Override to read from
  # ENV vars or another secret store.
  #
  # c.turnstile_credentials = -> { { site_key: ENV["TURNSTILE_SITE_KEY"], secret: ENV["TURNSTILE_SECRET"] } }
  # c.ipqs_credentials      = -> { { key: ENV["IPQS_KEY"] } }

  # Kill switch — until this returns true, every signal stays log-only.
  # Default reads `Rails.application.credentials.dig(env, :signup_enforcement, :enabled)`.
  # c.enforcement_enabled = -> { Rails.env.production? }
end
