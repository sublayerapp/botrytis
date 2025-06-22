# frozen_string_literal: true

require "cucumber"
require "rspec"
require_relative "test_config"

# Load Botrytis for Cucumber integration
require "botrytis"
puts "🔧 Loading Botrytis cucumber integration..."
require "botrytis/cucumber"
# Botrytis cucumber integration loaded

# Configure RSpec expectations for Cucumber
World(RSpec::Matchers)

# Note: Cucumber configuration is handled automatically in modern versions

# Botrytis integration test environment loaded