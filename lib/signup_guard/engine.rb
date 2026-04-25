# frozen_string_literal: true

module SignupGuard
  class Engine < ::Rails::Engine
    isolate_namespace SignupGuard

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    initializer "signup_guard.assets" do |app|
      # Host app's frontend bundler picks up the Stimulus controller from
      # signup_guard/javascript/. We don't ship a precompiled bundle —
      # FingerprintJS is a host-app dependency to avoid duplicate bundling.
    end
  end
end
