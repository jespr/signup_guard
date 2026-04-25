# frozen_string_literal: true

module SignupGuard
  class Signal < ApplicationRecord
    self.table_name = "signup_guard_signals"

    belongs_to :user, class_name: SignupGuard.configuration.user_class, optional: true

    enum :risk_level,
      {low: "low", medium: "medium", high: "high", block: "block"},
      default: :low
  end
end
