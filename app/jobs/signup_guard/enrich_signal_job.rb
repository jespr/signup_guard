# frozen_string_literal: true

module SignupGuard
  class EnrichSignalJob < ActiveJob::Base
    queue_as { SignupGuard.configuration.job_queue }

    retry_on StandardError, wait: :polynomially_longer, attempts: 3

    def perform(signal_id)
      signal = SignupGuard::Signal.find_by(id: signal_id)
      return unless signal

      result = SignupGuard::IpQualityScore.lookup(signal.ip_address)
      return if result.equal?(SignupGuard::IpQualityScore::EMPTY)

      signal.assign_attributes(
        ip_risk_score: result.fraud_score,
        asn: result.asn,
        country_code: result.country_code,
        raw_signals: signal.raw_signals.merge(
          "is_vpn" => result.is_vpn,
          "is_tor" => result.is_tor,
          "is_datacenter" => result.is_datacenter
        )
      )

      previous_level = signal.risk_level
      scorer = SignupGuard::RiskScorer.new(signal)
      signal.risk_score = scorer.score
      signal.risk_level = scorer.level
      signal.save!

      flag_user_if_upgraded(signal, previous_level)
    end

    private

    def flag_user_if_upgraded(signal, previous_level)
      return unless SignupGuard::RiskScorer::ACTION_LEVELS.include?(signal.risk_level)
      return if SignupGuard::RiskScorer::ACTION_LEVELS.include?(previous_level)
      return unless signal.user && SignupGuard::Enforcement.enabled?

      signal.user.update!(SignupGuard.configuration.requires_review_attribute => true)
    end
  end
end
