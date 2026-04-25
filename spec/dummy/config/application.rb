# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)
require "signup_guard"

module Dummy
  class Application < Rails::Application
    config.load_defaults 7.1
    config.eager_load = false
    config.active_support.deprecation = :stderr
    config.secret_key_base = "dummy-test-secret"
    config.cache_store = :memory_store
    config.active_job.queue_adapter = :test
  end
end
