# frozen_string_literal: true

require_relative "lib/signup_guard/version"

Gem::Specification.new do |spec|
  spec.name = "signup_guard"
  spec.version = SignupGuard::VERSION
  spec.authors = ["Jesper Christiansen"]
  spec.email = ["hi@jespr.com"]

  spec.summary = "Layered signup abuse detection for Rails apps"
  spec.description = <<~DESC
    Captures every signup attempt with rich signals (honeypot, fingerprint, MX,
    Turnstile, IP reputation, fingerprint reuse, IP burst), composes them into
    a risk score, and optionally enforces outcomes (allow / review / block) at
    the controller layer. Ships an admin UI for the captured data.
  DESC
  spec.homepage = "https://github.com/jespr/signup_guard"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,db,lib,data}/**/*", "MIT-LICENSE", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.1"
  spec.add_dependency "httparty", "~> 0.21"
  spec.add_dependency "mail", "~> 2.8"

  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "sqlite3"
end
