# Create sample products
Product.create!([
  { name: "Buy Now Button", price: 29.99, description: "A premium digital button for your e-commerce needs" },
  { name: "Add to Cart Widget", price: 49.99, description: "Revolutionary shopping cart addition mechanism" },
  { name: "Purchase Confirmation Modal", price: 19.99, description: "Beautiful confirmation dialog for completed purchases" }
])

# Create sample user for testing
User.create!(
  name: "Test User", 
  email: "test@example.com", 
  password_digest: "test_password_hash"
)

puts "Seeded #{Product.count} products and #{User.count} user"
