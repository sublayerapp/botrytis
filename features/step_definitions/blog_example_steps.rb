# frozen_string_literal: true

require_relative '../../lib/botrytis/cucumber'

# These are the "canonical" step definitions that the semantic matcher
# should match against for the blog post examples

Given(/^the user has logged in to their account$/) do
  @user_logged_in = true
  # User authentication step executed
end

When(/^they click the "([^"]*)" button$/) do |button_name|
  @button_clicked = button_name
  # Button interaction step executed: #{button_name}
end

Then(/^they should see a confirmation message$/) do
  @confirmation_shown = true
  # Confirmation step executed
end

# Test setup step
Given(/^Botrytis is configured for testing$/) do
  # This step sets up the test environment
  # In a real scenario, this would configure Botrytis
  # Botrytis test configuration loaded
end

# Verification steps to ensure our test steps actually ran
Then(/^the authentication step should have executed$/) do
  expect(@user_logged_in).to be true
end

Then(/^the button interaction step should have executed with "([^"]*)"$/) do |expected_button|
  expect(@button_clicked).to eq(expected_button)
end

Then(/^the confirmation step should have executed$/) do
  expect(@confirmation_shown).to be true
end