# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  # rspec-rails not installed yet — `bundle install` first
  task :default do
    abort "Run `bundle install` to install dev dependencies, then `rake spec`."
  end
end
