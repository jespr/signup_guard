# frozen_string_literal: true

module SignupGuard
  module CapturesSignals
    extend ActiveSupport::Concern

    MAX_REASONABLE_FILL_MS = 60 * 60 * 1000

    included do
      before_action :enforce_signup_risk, only: :create
      after_action :capture_signup_signal, only: :create
    end

    private

    def capture_signup_signal(overrides: {})
      persist_signup_signal(build_signup_signal(overrides))
    rescue => e
      Rails.logger.warn("[signup_guard] capture failed: #{e.class}: #{e.message}")
      SignupGuard.configuration.error_reporter.call(e)
    end

    def build_signup_signal(overrides = {})
      return @signup_guard_signal if defined?(@signup_guard_signal) && overrides.empty?

      email = SignupGuard.configuration.email_param.call(params).to_s.strip
      domain = extract_domain(email)

      signal = SignupGuard::Signal.new({
        email: email.presence,
        email_domain: domain,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        referrer: request.referer,
        honeypot_triggered: params[:website].present?,
        time_to_submit_ms: signup_guard_time_to_submit_ms,
        fingerprint: params[:fingerprint].presence,
        disposable_email: SignupGuard::DisposableEmail.disposable_domain?(domain),
        mx_valid: domain.present? ? SignupGuard::MxCheck.valid?(domain) : nil,
        turnstile_score: signup_guard_turnstile_score
      }.merge(overrides))

      scorer = SignupGuard::RiskScorer.new(signal)
      signal.risk_score = scorer.score
      signal.risk_level = scorer.level

      @signup_guard_signal = signal
    end

    def persist_signup_signal(signal)
      user = SignupGuard.configuration.user_resolver.call(self)
      signal.user = user if user&.persisted? && signal.user.nil?
      signal.save!
      SignupGuard::EnrichSignalJob.perform_later(signal.id) if SignupGuard::IpQualityScore.configured?
      signal
    end

    def enforce_signup_risk
      return if SignupGuard.configuration.bypass_signup.call(self)

      signal = build_signup_signal
      return unless SignupGuard::Enforcement.outcome_for(signal.risk_level) == :block

      persist_signup_signal(signal)
      Rails.logger.info "[signup_guard] blocked signal=#{signal.id} score=#{signal.risk_score} ip=#{signal.ip_address}"
      redirect_to main_app.respond_to?(:pending_review_users_path) ? main_app.pending_review_users_path : "/"
    end

    def extract_domain(email)
      return if email.blank?
      ::Mail::Address.new(email.downcase).domain
    rescue
      nil
    end

    def signup_guard_turnstile_score
      return unless SignupGuard::Turnstile.configured?
      SignupGuard::Turnstile.verify(params["cf-turnstile-response"], request.remote_ip).score
    end

    def signup_guard_time_to_submit_ms
      rendered_at = params[:form_rendered_at].to_i
      return if rendered_at.zero?
      elapsed = (Time.current.to_f * 1000).to_i - rendered_at
      return unless elapsed.positive? && elapsed <= MAX_REASONABLE_FILL_MS
      elapsed
    end
  end
end
