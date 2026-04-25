# frozen_string_literal: true

require "rails/engine"
require "httparty"
require "mail"

require "signup_guard/version"
require "signup_guard/configuration"
require "signup_guard/engine"

require "signup_guard/risk_scorer"
require "signup_guard/disposable_email"
require "signup_guard/mx_check"
require "signup_guard/turnstile"
require "signup_guard/ip_quality_score"
require "signup_guard/enforcement"

module SignupGuard
  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def reset!
      @configuration = nil
    end
  end
end
