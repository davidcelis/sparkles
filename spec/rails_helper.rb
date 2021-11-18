# This file is copied to spec/ when you run "rails generate rspec:install"
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# Add additional requires below this line. Rails is not loaded until this point!
require "sidekiq/testing"
require "vcr"

VCR.configure do |c|
  c.hook_into :webmock
  c.cassette_library_dir = Rails.root.join("spec", "fixtures", "cassettes")

  c.filter_sensitive_data("<SLACK_CLIENT_ID>") { Rails.application.credentials.dig(:slack, :client_id) }
  c.filter_sensitive_data("<SLACK_CLIENT_SECRET>") { Rails.application.credentials.dig(:slack, :client_secret) }
  c.filter_sensitive_data("<SLACK_SIGNING_SECRET>") { Rails.application.credentials.dig(:slack, :signing_secret) }

  # Make sure to filter out any OAuth Bearer tokens from specs
  c.filter_sensitive_data("<BEARER_TOKEN>") do |interaction|
    auths = interaction.request.headers["Authorization"]&.first
    if (match = auths&.match /^Bearer\s+([^,\s]+)/)
      match.captures.first
    end
  end
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
Dir[Rails.root.join("spec", "support", "**", "*.rb")].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # Allow using FactoryBot methods without having to call them directly on
  # the FactoryBot class.
  config.include FactoryBot::Syntax::Methods
  config.include Mocktail::DSL
  config.after(:each) { Mocktail.reset }

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # Arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
