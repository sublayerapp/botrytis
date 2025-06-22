# Setup steps
Given(/^the products are available in the store$/) do
  # Products are seeded in db/seeds.rb, nothing to do here
end

# Authentication steps
Given(/^the user has logged in to their account$/) do
  visit login_path
  fill_in 'email', with: 'test@example.com'
  click_button 'Login'
  expect(page).to have_content('Successfully logged in!')
end

# Navigation steps  
When(/^they visit the products page$/) do
  visit products_path
end

When(/^they go to the shopping cart$/) do
  visit cart_path
end

When(/^they navigate to the checkout page$/) do
  visit checkout_path
end

# Product interaction steps
When(/^they click the "([^"]*)" button$/) do |button_text|
  click_button button_text
end

When(/^they select the "([^"]*)" product$/) do |product_name|
  click_link product_name
end

# Shopping actions
When(/^they add the item to their cart$/) do
  click_button 'Add to Cart'
end

When(/^they proceed to purchase$/) do
  click_button 'Complete Purchase'
end

# Verification steps
Then(/^they should see a confirmation message$/) do
  expect(page).to have_content('Thank you for your purchase!')
end

Then(/^they should see the products list$/) do
  expect(page).to have_content('Products')
end

Then(/^they should see their cart contents$/) do
  expect(page).to have_content('Shopping Cart')
end

Then(/^they should be on the checkout page$/) do
  expect(current_path).to eq(checkout_path)
end