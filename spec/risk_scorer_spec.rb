# frozen_string_literal: true

require "spec_helper"

RSpec.describe SignupGuard::RiskScorer do
  def signal(**attrs)
    SignupGuard::Signal.new(attrs)
  end

  it "scores a clean signal at zero" do
    s = signal(fingerprint: "fp-1", time_to_submit_ms: 8_000, mx_valid: true, ip_address: "1.1.1.1")
    expect(described_class.new(s).score).to eq 0
    expect(described_class.new(s).level).to eq "low"
  end

  it "honeypot alone is enough to block" do
    s = signal(honeypot_triggered: true, fingerprint: "fp", mx_valid: true)
    scorer = described_class.new(s)
    expect(scorer.score).to be >= 100
    expect(scorer.level).to eq "block"
  end

  it "respects custom weights via configuration" do
    SignupGuard.configuration.scorer_weights[:disposable_email] = 1
    s = signal(disposable_email: true, fingerprint: "fp", mx_valid: true)
    expect(described_class.new(s).score).to eq 1
  end

  it "treats raw_signals[:is_tor] as the tor_exit signal" do
    s = signal(raw_signals: {"is_tor" => true}, fingerprint: "fp", mx_valid: true)
    expect(described_class.new(s).triggered_signals).to include(:tor_exit)
  end

  describe "level boundaries" do
    def level_for(score)
      scorer = described_class.new(signal)
      scorer.instance_variable_set(:@score, score)
      scorer.level
    end

    it "29 is low, 30 is medium" do
      expect(level_for(29)).to eq "low"
      expect(level_for(30)).to eq "medium"
    end

    it "59 is medium, 60 is high" do
      expect(level_for(59)).to eq "medium"
      expect(level_for(60)).to eq "high"
    end

    it "99 is high, 100 is block" do
      expect(level_for(99)).to eq "high"
      expect(level_for(100)).to eq "block"
    end
  end
end
