# frozen_string_literal: true

# The engine deliberately ships no routes. Host apps mount the admin views
# (when added) and the pending_review page in their own `config/routes.rb`,
# so URLs follow the host app's conventions.

SignupGuard::Engine.routes.draw do
end
