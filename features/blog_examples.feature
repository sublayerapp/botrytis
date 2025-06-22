Feature: Blog Post Semantic Matching Examples
  As a developer reading the blog post
  I want the examples to actually work
  So that I can trust the marketing material

  Background:
    Given Botrytis is configured for testing

  Scenario: Authentication variations should work
    Given the user has authenticated successfully
    When they hit the purchase button
    Then they receive a success notification

  Scenario: Exact matches still work
    Given the user has logged in to their account
    When they click the "Buy Now" button  
    Then they should see a confirmation message

  Scenario: Press vs Click variations
    Given the user has signed in to their account
    When they press the "Buy Now" button
    Then they should view a confirmation message

  Scenario: Multiple semantic variations in one scenario
    Given the user has authenticated successfully
    When they tap the "Buy Now" button
    Then they get a notification

  Scenario: Humorous button interactions
    Given the user has logged in to their account
    When they gently caresses the "Buy Now" button
    Then they should see a confirmation message

  Scenario: Casual language variations
    Given the user has signed in to their account
    When they mash the buy button
    Then they receive a success notification