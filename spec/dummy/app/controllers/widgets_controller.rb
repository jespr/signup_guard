# frozen_string_literal: true

# Generic resource controller used in specs to verify that BlocksPendingReview
# gates create actions for users with requires_review? truthy.
class WidgetsController < ApplicationController
  include SignupGuard::BlocksPendingReview

  def create
    render plain: "widget created"
  end
end
