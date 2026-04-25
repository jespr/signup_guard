# frozen_string_literal: true

module SignupGuard
  module BlocksPendingReview
    extend ActiveSupport::Concern

    included do
      before_action :block_pending_review, only: :create
    end

    private

    def block_pending_review
      attribute = SignupGuard.configuration.requires_review_attribute
      return unless current_user&.public_send(attribute)
      redirect_to main_app.respond_to?(:pending_review_users_path) ? main_app.pending_review_users_path : "/",
        alert: "Your account is under review."
    end
  end
end
