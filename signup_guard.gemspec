# frozen_string_literal: true

require_relative "lib/signup_guard/version"

Gem::Specification.new do |spec|
  spec.name = "signup_guard"
  spec.version = SignupGuard::VERSION
  spec.authors = ["Jesper Christiansen"]
  spec.email = ["hi@jespr.com"]

  spec.summary = "Risk-score Rails signups and gate suspicious accounts before they cause damage."
  spec.description = <<~DESC
    SignupGuard captures every signup attempt with a layered set of cheap
    signals — honeypot, time-to-submit, FingerprintJS, MX records, Cloudflare
    Turnstile, disposable-email lists, IP reputation, fingerprint reuse, and
    IP-burst detection — and composes them into a single tunable risk score.
    Ship it in shadow mode to build a baseline, then flip a credentials flag
    to start silently blocking the worst attempts and routing the suspicious
    ones into a review queue.
  DESC
  spec.homepage = "https://github.com/jespr/signup_guard"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,db,lib,data}/**/*", "MIT-LICENSE", "README.md", "CHANGELOG.md"]
  end

  spec.add_dependency "rails", ">= 7.1", "< 9"
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "mail", "~> 2.8"

  spec.add_development_dependency "rspec-rails", "~> 8.0"
  spec.add_development_dependency "webmock", "~> 3.0"
  spec.add_development_dependency "sqlite3", "~> 2.0"
  spec.add_development_dependency "appraisal", "~> 2.5"
end
