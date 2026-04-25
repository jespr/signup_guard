# frozen_string_literal: true

class SignupsController < ApplicationController
  include SignupGuard::CapturesSignals

  def create
    self.resource = User.new(email: params.dig(:user, :email))
    if resource.save
      render plain: "ok"
    else
      render plain: "bad", status: :unprocessable_entity
    end
  end

  def pending_review
    render plain: "Account under review"
  end
end
