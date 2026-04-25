# frozen_string_literal: true

module SignupGuard
  class RiskScorer
    DEFAULT_WEIGHTS = {
      honeypot_triggered: 100,
      turnstile_failed: 60,
      tor_exit: 50,
      disposable_email: 40,
      fingerprint_reused: 40,
      high_ip_risk: 40,
      too_fast: 35,
      mx_invalid: 30,
      datacenter_ip: 30,
      ip_burst: 25,
      suspiciously_fast: 15,
      no_fingerprint: 10,
      freemail_with_digits: 10
    }.freeze

    DEFAULT_THRESHOLDS = {
      "block" => 100..,
      "high" => 60..99,
      "medium" => 30..59,
      "low" => 0..29
    }.freeze

    ACTION_LEVELS = %w[high block].freeze

    TOO_FAST_MS = 1_000
    SUSPICIOUSLY_FAST_MS = 3_000
    TURNSTILE_FAIL_THRESHOLD = 0.5
    IP_BURST_THRESHOLD = 3
    IP_BURST_WINDOW = 24 * 60 * 60
    FINGERPRINT_REUSE_THRESHOLD = 5
    FINGERPRINT_REUSE_WINDOW = 7 * 24 * 60 * 60
    HIGH_IP_RISK_THRESHOLD = 75

    def initialize(signal, weights: SignupGuard.configuration.scorer_weights, thresholds: SignupGuard.configuration.scorer_thresholds)
      @signal = signal
      @weights = weights
      @thresholds = thresholds
    end

    def score
      @score ||= triggered_signals.sum { |s| @weights.fetch(s, 0) }
    end

    def level
      @thresholds.find { |_, range| range.cover?(score) }.first
    end

    def triggered_signals
      @triggered_signals ||= [
        (:honeypot_triggered if @signal.honeypot_triggered),
        (:turnstile_failed if turnstile_failed?),
        (:tor_exit if raw?(:is_tor)),
        (:disposable_email if @signal.disposable_email),
        (:fingerprint_reused if fingerprint_reused?),
        (:high_ip_risk if high_ip_risk?),
        (:too_fast if too_fast?),
        (:mx_invalid if @signal.mx_valid == false),
        (:datacenter_ip if raw?(:is_datacenter)),
        (:ip_burst if ip_burst?),
        (:suspiciously_fast if suspiciously_fast?),
        (:no_fingerprint if @signal.fingerprint.blank?),
        (:freemail_with_digits if freemail_with_digits?)
      ].compact
    end

    private

    def turnstile_failed?
      @signal.turnstile_score && @signal.turnstile_score < TURNSTILE_FAIL_THRESHOLD
    end

    def too_fast?
      @signal.time_to_submit_ms && @signal.time_to_submit_ms < TOO_FAST_MS
    end

    def suspiciously_fast?
      ms = @signal.time_to_submit_ms
      ms && ms >= TOO_FAST_MS && ms < SUSPICIOUSLY_FAST_MS
    end

    def fingerprint_reused?
      return false if @signal.fingerprint.blank?
      recent_count(:fingerprint, @signal.fingerprint, FINGERPRINT_REUSE_WINDOW, FINGERPRINT_REUSE_THRESHOLD) >= FINGERPRINT_REUSE_THRESHOLD - 1
    end

    def ip_burst?
      return false if @signal.ip_address.blank?
      recent_count(:ip_address, @signal.ip_address, IP_BURST_WINDOW, IP_BURST_THRESHOLD) >= IP_BURST_THRESHOLD - 1
    end

    def recent_count(field, value, window_seconds, threshold)
      SignupGuard::Signal
        .where(field => value)
        .where("created_at > ?", Time.current - window_seconds)
        .limit(threshold)
        .count
    end

    def freemail_with_digits?
      return false if @signal.email.blank?
      return false unless DisposableEmail::FREEMAIL_DOMAINS.include?(@signal.email_domain&.downcase)
      local_part.scan(/\d/).length >= 3
    end

    def local_part
      Mail::Address.new(@signal.email.downcase).local.to_s
    rescue
      ""
    end

    def high_ip_risk?
      @signal.ip_risk_score && @signal.ip_risk_score > HIGH_IP_RISK_THRESHOLD
    end

    def raw?(key)
      @signal.raw_signals&.dig(key.to_s) == true
    end
  end
end
