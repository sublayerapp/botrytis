Feature: Semantic E-commerce Flow
  As a developer writing BDD tests
  I want to use natural language in my Gherkin scenarios  
  So that my tests are readable and my team can contribute easily

  Background:
    Given the products are available in the store

  Scenario: Authentication variations should work seamlessly
    Given the user has logged in to their account
    When they visit the products page
    Then they should see the products list

  Scenario: Natural language for user authentication  
    Given the user has authenticated successfully
    When they go to the products page
    Then they should see the products list

  Scenario: Shopping with various action verbs
    Given the user has logged in to their account
    When they browse to the products page
    And they select the "Buy Now Button" product
    And they add the item to their cart
    Then they should see their cart contents

  Scenario: Button interaction variations
    Given the user has signed in to their account
    When they visit the products page
    And they choose the "Add to Cart Widget" product
    And they press the "Add to Cart" button
    Then they should see their cart contents

  Scenario: Purchase flow with natural language
    Given the user has authenticated successfully
    When they navigate to the products page
    And they select the "Purchase Confirmation Modal" product
    And they add the item to their cart
    And they go to the shopping cart
    And they tap the "Checkout" button
    And they proceed to purchase
    Then they should see a confirmation message

  Scenario: Checkout flow with mixed exact and semantic matches
    Given the user has logged in to their account
    When they visit the products page
    And they pick the "Buy Now Button" product
    And they add the item to their cart
    And they navigate to the checkout page
    And they hit the "Complete Purchase" button
    Then they should view a confirmation message