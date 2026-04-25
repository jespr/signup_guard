# frozen_string_literal: true

require "spec_helper"
require "rails/generators"
require "rails/generators/test_case"
require "generators/signup_guard/install/install_generator"

RSpec.describe SignupGuard::Generators::InstallGenerator do
  let(:tmp) { File.expand_path("../tmp", __dir__) }

  before do
    FileUtils.rm_rf(tmp)
    FileUtils.mkdir_p(tmp)
    described_class.remove_method(:copy_engine_migrations) if described_class.method_defined?(:copy_engine_migrations)
    described_class.define_method(:copy_engine_migrations) { }
  end

  after { FileUtils.rm_rf(tmp) }

  def invoke_generator(args = [])
    described_class.start(args, destination_root: tmp)
  end

  it "writes the initializer with default options" do
    invoke_generator(["--skip-user-migration"])
    initializer = File.read(File.join(tmp, "config/initializers/signup_guard.rb"))
    expect(initializer).to include('c.user_class = "User"')
    expect(initializer).to include("c.requires_review_attribute = :requires_review")
  end

  it "respects custom user class and attribute name" do
    invoke_generator(["--user-class=Account", "--requires-review-attribute=needs_review"])
    initializer = File.read(File.join(tmp, "config/initializers/signup_guard.rb"))
    expect(initializer).to include('c.user_class = "Account"')
    expect(initializer).to include("c.requires_review_attribute = :needs_review")

    migration = Dir[File.join(tmp, "db/migrate/*_add_needs_review_to_accounts.rb")].first
    expect(migration).to be_present
    expect(File.read(migration)).to include("add_column :accounts, :needs_review, :boolean")
  end

  it "skips initializer with --skip-initializer" do
    invoke_generator(["--skip-initializer", "--skip-user-migration"])
    expect(File.exist?(File.join(tmp, "config/initializers/signup_guard.rb"))).to be false
  end

  it "copies the Stimulus controller to the default path" do
    invoke_generator(["--skip-user-migration"])
    js = File.join(tmp, "app/javascript/controllers/signup_timer_controller.js")
    expect(File.exist?(js)).to be true
    expect(File.read(js)).to include("FingerprintJS.load")
  end

  it "respects --stimulus-path" do
    invoke_generator(["--skip-user-migration", "--stimulus-path=app/javascript/src/signup.js"])
    expect(File.exist?(File.join(tmp, "app/javascript/src/signup.js"))).to be true
  end

  it "skips Stimulus controller with --skip-stimulus" do
    invoke_generator(["--skip-user-migration", "--skip-stimulus"])
    expect(File.exist?(File.join(tmp, "app/javascript/controllers/signup_timer_controller.js"))).to be false
  end
end
