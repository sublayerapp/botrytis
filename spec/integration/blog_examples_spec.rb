# frozen_string_literal: true

require "spec_helper"
require "cucumber"
require "botrytis"

RSpec.describe "Blog Examples Integration" do
  let(:semantic_matcher) { Botrytis::SemanticMatcher.new }
  let(:mock_step_definitions) do
    [
      create_mock_step_definition("Given the user has logged in to their account"),
      create_mock_step_definition('When they click the "Buy Now" button'),
      create_mock_step_definition("Then they should see a confirmation message")
    ]
  end

  before do
    Botrytis.configure do |config|
      config.confidence_threshold = 0.7
      config.cache_enabled = false
    end

    # Mock LLM responses for consistent testing
    allow_any_instance_of(Botrytis::SemanticMatchGenerator).to receive(:generate).and_return(
      double("MatchResult", 
        match_found: "yes",
        confidence: "0.85",
        best_match_pattern: "mocked_pattern",
        parameter_values: ""
      )
    )
  end

  describe "Authentication Variations" do
    let(:auth_step_def) { create_mock_step_definition("Given the user has logged in to their account") }
    let(:available_steps) { [auth_step_def] }

    it "matches exact step text" do
      # Even exact matches go through the LLM, so we need to mock the response
      mock_llm_response(
        step_text: "Given the user has logged in to their account",
        best_match: "Given the user has logged in to their account",
        confidence: 1.0
      )

      result = semantic_matcher.find_match("Given the user has logged in to their account", available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'signed in' variation" do
      mock_llm_response(
        step_text: "Given the user has signed in to their account",
        best_match: "Given the user has logged in to their account",
        confidence: 0.9
      )

      result = semantic_matcher.find_match("Given the user has signed in to their account", available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'authenticated successfully' variation" do
      mock_llm_response(
        step_text: "Given the user has authenticated successfully",
        best_match: "Given the user has logged in to their account", 
        confidence: 0.85
      )

      result = semantic_matcher.find_match("Given the user has authenticated successfully", available_steps)
      expect(result).not_to be_nil
    end
  end

  describe "Button Interaction Variations" do
    let(:button_step_def) { create_mock_step_definition('When they click the "Buy Now" button') }
    let(:available_steps) { [button_step_def] }

    it "matches exact step text" do
      mock_llm_response(
        step_text: 'When they click the "Buy Now" button',
        best_match: 'When they click the "Buy Now" button',
        confidence: 1.0
      )

      result = semantic_matcher.find_match('When they click the "Buy Now" button', available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'press' variation" do
      mock_llm_response(
        step_text: 'When they press the "Buy Now" button',
        best_match: 'When they click the "Buy Now" button',
        confidence: 0.9
      )

      result = semantic_matcher.find_match('When they press the "Buy Now" button', available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'tap' variation" do
      mock_llm_response(
        step_text: 'When they tap the "Buy Now" button',
        best_match: 'When they click the "Buy Now" button',
        confidence: 0.88
      )

      result = semantic_matcher.find_match('When they tap the "Buy Now" button', available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'hit the purchase button' variation" do
      mock_llm_response(
        step_text: "When they hit the purchase button",
        best_match: 'When they click the "Buy Now" button',
        confidence: 0.82
      )

      result = semantic_matcher.find_match("When they hit the purchase button", available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'mash the buy button' variation" do
      mock_llm_response(
        step_text: "When they mash the buy button",
        best_match: 'When they click the "Buy Now" button',
        confidence: 0.75
      )

      result = semantic_matcher.find_match("When they mash the buy button", available_steps)
      expect(result).not_to be_nil
    end

    it "handles humorous 'gently caresses' variation" do
      mock_llm_response(
        step_text: 'When they gently caresses the "Buy Now" button',
        best_match: 'When they click the "Buy Now" button',
        confidence: 0.72
      )

      result = semantic_matcher.find_match('When they gently caresses the "Buy Now" button', available_steps)
      expect(result).not_to be_nil
    end
  end

  describe "Confirmation Message Variations" do
    let(:confirm_step_def) { create_mock_step_definition("Then they should see a confirmation message") }
    let(:available_steps) { [confirm_step_def] }

    it "matches exact step text" do
      mock_llm_response(
        step_text: "Then they should see a confirmation message",
        best_match: "Then they should see a confirmation message",
        confidence: 1.0
      )

      result = semantic_matcher.find_match("Then they should see a confirmation message", available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'view' variation" do
      mock_llm_response(
        step_text: "Then they should view a confirmation message",
        best_match: "Then they should see a confirmation message",
        confidence: 0.92
      )

      result = semantic_matcher.find_match("Then they should view a confirmation message", available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'receive a success notification' variation" do
      mock_llm_response(
        step_text: "Then they receive a success notification",
        best_match: "Then they should see a confirmation message",
        confidence: 0.8
      )

      result = semantic_matcher.find_match("Then they receive a success notification", available_steps)
      expect(result).not_to be_nil
    end

    it "matches 'get a notification' variation" do
      mock_llm_response(
        step_text: "Then they get a notification",
        best_match: "Then they should see a confirmation message",
        confidence: 0.78
      )

      result = semantic_matcher.find_match("Then they get a notification", available_steps)
      expect(result).not_to be_nil
    end
  end

  describe "Confidence Threshold Behavior" do
    let(:available_steps) { [create_mock_step_definition("Given some step")] }

    it "rejects matches below confidence threshold" do
      mock_llm_response(
        step_text: "Given completely unrelated step",
        best_match: "Given some step",
        confidence: 0.5  # Below 0.7 threshold
      )

      result = semantic_matcher.find_match("Given completely unrelated step", available_steps)
      expect(result).to be_nil
    end

    it "accepts matches at threshold" do
      mock_llm_response(
        step_text: "Given similar step",
        best_match: "Given some step", 
        confidence: 0.7  # At threshold
      )

      result = semantic_matcher.find_match("Given similar step", available_steps)
      expect(result).not_to be_nil
    end
  end

  private

  def create_mock_step_definition(pattern)
    # Create a proper regexp from the pattern
    regexp = case pattern
    when /Given the user has logged in to their account/
      /^Given the user has logged in to their account$/
    when /When they click the "([^"]*)" button/
      /^When they click the "([^"]*)" button$/
    when /Then they should see a confirmation message/
      /^Then they should see a confirmation message$/
    else
      Regexp.new("^#{Regexp.escape(pattern)}$")
    end

    double("StepDefinition",
      regexp_source: pattern,
      regexp: regexp,
      proc: proc {},
      to_s: pattern,
      match: ->(text) { regexp.match(text) }
    )
  end

  def mock_llm_response(step_text:, best_match:, confidence:, params: [])
    allow_any_instance_of(Botrytis::SemanticMatchGenerator).to receive(:generate).and_return(
      double("MatchResult",
        match_found: "yes", 
        confidence: confidence.to_s,
        best_match_pattern: best_match,
        parameter_values: params
      )
    )
  end
end