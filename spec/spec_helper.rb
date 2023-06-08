# frozen_string_literal: true

require "pathname"
require "json"
require "yaml"
require "langchain"
require "pry-byebug"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect

    # Only run integration tests if desired
    config.filter_run_excluding type: :integration unless ENV["INTEGRATION"]
  end
end
