Rails.application.routes.draw do
  root "home#index"
  
  # Authentication
  get "login", to: "sessions#new"
  post "login", to: "sessions#create" 
  delete "logout", to: "sessions#destroy"
  
  # Products
  get "products", to: "products#index"
  get "products/:id", to: "products#show", as: :product
  
  # Shopping cart
  get "cart", to: "cart_items#index"
  post "cart_items", to: "cart_items#create"
  delete "cart/:id", to: "cart_items#destroy", as: :cart_item
  
  # Orders
  get "checkout", to: "orders#new"
  post "checkout", to: "orders#new"
  post "orders", to: "orders#create"
  get "orders/:id", to: "orders#show", as: :order
  get "confirmation", to: "orders#show"
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end