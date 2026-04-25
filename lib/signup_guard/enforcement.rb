# frozen_string_literal: true

module SignupGuard
  module Enforcement
    module_function

    def outcome_for(risk_level)
      return :allow unless enabled?

      case risk_level
      when "block" then :block
      when "high" then :review
      else :allow
      end
    end

    def enabled?
      SignupGuard.configuration.enforcement_enabled.call
    end
  end
end
