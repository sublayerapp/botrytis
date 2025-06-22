class OrdersController < ApplicationController
  def new
    # Checkout page
    @cart_items = CartItem.joins(:product).where(user_id: session[:user_id] || 1)
    @total = @cart_items.sum { |item| item.quantity * item.product.price }
  end

  def create
    # Complete purchase
    user_id = session[:user_id] || 1
    cart_items = CartItem.joins(:product).where(user_id: user_id)
    
    if cart_items.any?
      # Create order
      total_amount = cart_items.sum { |item| item.quantity * item.product.price }
      order = Order.create!(
        user_id: user_id,
        total: total_amount,
        status: 'completed'
      )
      
      # Clear cart
      cart_items.destroy_all
      
      redirect_to order_path(order), notice: "Thank you for your purchase!"
    else
      redirect_to cart_path, alert: "Your cart is empty"
    end
  end

  def show
    @order = Order.find(params[:id])
  end
end
