# frozen_string_literal: true

module SignupGuard
  class Configuration
    # --- User model integration ---

    # Which AR class represents users in the host app.
    attr_accessor :user_class
    # Boolean attribute on the user that gates create actions for high-risk accounts.
    attr_accessor :requires_review_attribute

    # --- Request -> Signal extractors ---

    # Extract email from the request. Default works with Devise's nested params.
    attr_accessor :email_param
    # Predicate that returns true when this request should bypass enforcement
    # entirely (e.g. invitation flows). Receives the controller instance.
    attr_accessor :bypass_signup
    # Optional hook to find the persisted user inside the controller. Receives
    # the controller; returns a User-or-nil. Default reads `controller.resource`
    # for Devise compatibility.
    attr_accessor :user_resolver

    # --- Scoring ---

    # Override individual weights without forking the gem.
    attr_reader :scorer_weights
    # Override risk-level thresholds (hash of "name" => Range).
    attr_accessor :scorer_thresholds

    # --- External services ---

    # Lambdas returning credential hashes. We call them lazily so credential
    # rotation at runtime works without restart.
    attr_accessor :turnstile_credentials   # -> { site_key:, secret: }
    attr_accessor :ipqs_credentials        # -> { key: }
    attr_accessor :enforcement_enabled     # -> true|false

    # --- Cross-cutting ---

    # Where to send swallowed exceptions. Default is no-op.
    attr_accessor :error_reporter
    # ActiveJob queue for the async enrichment job.
    attr_accessor :job_queue
    # Path to the disposable email blocklist. Defaults to the file shipped in the gem.
    attr_accessor :disposable_domains_path

    def initialize
      @user_class                 = "User"
      @requires_review_attribute  = :requires_review
      @email_param                = ->(params) { params.dig(:user, :email) }
      @bypass_signup              = ->(_controller) { false }
      @user_resolver              = ->(controller) { controller.send(:resource) if controller.respond_to?(:resource, true) }
      @scorer_weights             = SignupGuard::RiskScorer::DEFAULT_WEIGHTS.dup
      @scorer_thresholds          = SignupGuard::RiskScorer::DEFAULT_THRESHOLDS.dup
      @turnstile_credentials      = -> { Rails.application.credentials.dig(Rails.env.to_sym, :turnstile) }
      @ipqs_credentials           = -> { Rails.application.credentials.dig(Rails.env.to_sym, :ipqualityscore) }
      @enforcement_enabled        = -> { Rails.application.credentials.dig(Rails.env.to_sym, :signup_enforcement, :enabled) == true }
      @error_reporter             = ->(_e) { }
      @job_queue                  = :default
      @disposable_domains_path    = SignupGuard::Engine.root.join("data/disposable_email_domains.txt")
    end

    def user_model
      user_class.constantize
    end
  end
end
