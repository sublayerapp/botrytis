class CartItemsController < ApplicationController
  def index
    @cart_items = CartItem.joins(:product).where(user_id: session[:user_id] || 1)
  end

  def create
    product = Product.find(params[:product_id])
    
    # Find or create cart item for this user and product
    cart_item = CartItem.find_or_initialize_by(
      user_id: session[:user_id] || 1, # Use session user or default
      product: product
    )
    
    if cart_item.persisted?
      cart_item.quantity += 1
    else
      cart_item.quantity = 1
    end
    
    cart_item.save!
    redirect_to cart_path, notice: "#{product.name} added to cart!"
  end

  def destroy
    cart_item = CartItem.find(params[:id])
    cart_item.destroy
    redirect_to cart_path, notice: "Item removed from cart"
  end
end
