# frozen_string_literal: true

require "botrytis"
require "ostruct"

# Test configuration for blog examples integration tests
#
# TESTING WITH LIVE API CALLS:
# To test with real API calls instead of mocks, set the environment variable:
#   BOTRYTIS_LIVE_API=true bundle exec cucumber
# 
# This will skip mock setup and make actual calls to the configured LLM provider.
# Ensure you have valid API credentials configured before running live tests.
Botrytis.configure do |config|
  config.confidence_threshold = 0.7
  config.cache_enabled = false  # Disable caching for consistent test results
  config.llm_provider = :openai
  config.model_name = "gpt-4o"
end

# Mock LLM responses for blog post examples to ensure consistent test results
# This prevents actual API calls during testing
module BlogExampleMocks
  MOCK_RESPONSES = {
    # Authentication variations (without Given/When/Then keywords)
    "the user has signed in to their account" => {
      match_found: "yes",
      best_match_pattern: "/^the user has logged in to their account$/",
      confidence: "0.9",
      parameter_values: ""
    },
    "the user has authenticated successfully" => {
      match_found: "yes", 
      best_match_pattern: "/^the user has logged in to their account$/",
      confidence: "0.85",
      parameter_values: ""
    },

    # Button interaction variations  
    'they press the "Buy Now" button' => {
      match_found: "yes",
      best_match_pattern: '/^they click the "([^"]*)" button$/',
      confidence: "0.9",
      parameter_values: "Buy Now"
    },
    'they tap the "Buy Now" button' => {
      match_found: "yes",
      best_match_pattern: '/^they click the "([^"]*)" button$/', 
      confidence: "0.88",
      parameter_values: "Buy Now"
    },
    "they hit the purchase button" => {
      match_found: "yes",
      best_match_pattern: '/^they click the "([^"]*)" button$/',
      confidence: "0.82", 
      parameter_values: "Buy Now"
    },
    "they mash the buy button" => {
      match_found: "yes",
      best_match_pattern: '/^they click the "([^"]*)" button$/',
      confidence: "0.75",
      parameter_values: "Buy Now"
    },
    'they gently caresses the "Buy Now" button' => {
      match_found: "yes",
      best_match_pattern: '/^they click the "([^"]*)" button$/',
      confidence: "0.72",
      parameter_values: "Buy Now"
    },

    # Confirmation message variations
    "they should view a confirmation message" => {
      match_found: "yes",
      best_match_pattern: "/^they should see a confirmation message$/",
      confidence: "0.92",
      parameter_values: ""
    },
    "they receive a success notification" => {
      match_found: "yes",
      best_match_pattern: "/^they should see a confirmation message$/",
      confidence: "0.8",
      parameter_values: ""
    },
    "they get a notification" => {
      match_found: "yes", 
      best_match_pattern: "/^they should see a confirmation message$/",
      confidence: "0.78",
      parameter_values: ""
    }
  }.freeze

  def self.mock_response_for(step_text)
    response_data = MOCK_RESPONSES[step_text]
    return nil unless response_data

    # Create a simple object that responds like SemanticMatchGenerator result
    OpenStruct.new(response_data)
  end

  def self.setup_mocks!
    # Skip mocking if BOTRYTIS_LIVE_API environment variable is set to true
    # This allows testing with real API calls during development
    return if ENV['BOTRYTIS_LIVE_API'] == 'true'
    
    # For Cucumber, we'll override the generate method directly instead of using RSpec mocks
    original_generate = Botrytis::SemanticMatchGenerator.instance_method(:generate)
    
    Botrytis::SemanticMatchGenerator.define_method(:generate) do
      step_text = @step_text
      mock_response = BlogExampleMocks.mock_response_for(step_text)
      
      # If we have a mock response, use it; otherwise return no match
      if mock_response
        mock_response
      else
        # For undefined steps, return a "no match" response
        OpenStruct.new(
          match_found: "no",
          best_match_pattern: "",
          confidence: "0.0", 
          parameter_values: ""
        )
      end
    end
  end
end

# Set up mocks when this file is loaded
BlogExampleMocks.setup_mocks!