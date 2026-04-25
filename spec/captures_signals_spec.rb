# frozen_string_literal: true

require "spec_helper"

RSpec.describe SignupsController, type: :request do
  describe "POST /signups" do
    it "captures a signal on a clean signup" do
      expect {
        post "/signups", params: {user: {email: "user@example.com"}}
      }.to change(SignupGuard::Signal, :count).by(1)

      signal = SignupGuard::Signal.last
      expect(signal.email).to eq "user@example.com"
      expect(signal.email_domain).to eq "example.com"
      expect(signal.user_id).to be_present
    end

    it "captures a signal even when signup fails" do
      expect {
        post "/signups", params: {user: {email: ""}}
      }.to change(SignupGuard::Signal, :count).by(1)

      expect(SignupGuard::Signal.last.user_id).to be_nil
    end

    it "scores honeypot-filled signups as block" do
      post "/signups", params: {user: {email: "spam@example.com"}, website: "spammer"}
      expect(SignupGuard::Signal.last.risk_level).to eq "block"
    end

    it "redirects block-level signups silently when enforcement is on" do
      SignupGuard.configuration.enforcement_enabled = -> { true }

      expect {
        post "/signups", params: {user: {email: "spam@example.com"}, website: "spammer"}
      }.not_to change(User, :count)

      expect(response).to redirect_to("/pending_review")
    end
  end
end

RSpec.describe WidgetsController, type: :request do
  it "redirects flagged users to pending review" do
    user = User.create!(email: "flagged@example.com", requires_review: true)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)

    post "/widgets"
    expect(response).to redirect_to("/pending_review")
  end

  it "lets healthy users through" do
    user = User.create!(email: "ok@example.com", requires_review: false)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)

    post "/widgets"
    expect(response.body).to eq "widget created"
  end
end
