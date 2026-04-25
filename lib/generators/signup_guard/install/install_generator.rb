# frozen_string_literal: true

require "rails/generators/active_record"

module SignupGuard
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      class_option :user_class,
        type: :string,
        default: "User",
        desc: "Host app user model class name"

      class_option :requires_review_attribute,
        type: :string,
        default: "requires_review",
        desc: "Boolean attribute on the user model that gates downstream creation"

      class_option :skip_user_migration,
        type: :boolean,
        default: false,
        desc: "Skip generating the requires_review column migration"

      class_option :skip_initializer,
        type: :boolean,
        default: false,
        desc: "Skip generating the config initializer"

      class_option :skip_stimulus,
        type: :boolean,
        default: false,
        desc: "Skip copying the Stimulus controller (useful for non-Stimulus frontends)"

      class_option :stimulus_path,
        type: :string,
        default: "app/javascript/controllers/signup_timer_controller.js",
        desc: "Where to copy the Stimulus controller"

      def self.next_migration_number(dirname)
        ::ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def copy_initializer
        return if options[:skip_initializer]
        template "signup_guard.rb", "config/initializers/signup_guard.rb"
      end

      def copy_engine_migrations
        rake "signup_guard:install:migrations"
      end

      def generate_user_migration
        return if options[:skip_user_migration]
        migration_template(
          "add_requires_review_to_users.rb",
          "db/migrate/add_#{options[:requires_review_attribute]}_to_#{user_table}.rb"
        )
      end

      def copy_stimulus_controller
        return if options[:skip_stimulus]
        copy_file "signup_timer_controller.js", options[:stimulus_path]
      end

      def show_post_install_message
        say "\nSignupGuard installed.", :green
        say "Next steps:"
        say "  1. bin/rails db:migrate"
        say "  2. bin/rails signup_guard:refresh_disposable_domains"
        unless options[:skip_stimulus]
          say "  3. Add @fingerprintjs/fingerprintjs to your frontend deps:"
          say "       yarn add @fingerprintjs/fingerprintjs    # esbuild/vite/jsbundling"
          say "       bin/importmap pin @fingerprintjs/fingerprintjs    # importmap"
          say "  4. Add the hidden fields and honeypot to your signup form (see README)"
        end
        say "  #{options[:skip_stimulus] ? 3 : 5}. Include SignupGuard::CapturesSignals in your signup controller"
        say "  #{options[:skip_stimulus] ? 4 : 6}. Include SignupGuard::BlocksPendingReview in any controller that"
        say "     creates resources flagged users shouldn't be able to create"
        say "  #{options[:skip_stimulus] ? 5 : 7}. Flip the kill switch when ready: add"
        say "       signup_enforcement: { enabled: true }"
        say "     to Rails credentials under your production env."
      end

      private

      def user_class
        options[:user_class]
      end

      def requires_review_attribute
        options[:requires_review_attribute]
      end

      def user_table
        user_class.tableize
      end

      def migration_class_name
        "Add#{requires_review_attribute.camelize}To#{user_table.camelize}"
      end

      def migration_version
        "[#{::ActiveRecord::Migration.current_version}]"
      end
    end
  end
end
