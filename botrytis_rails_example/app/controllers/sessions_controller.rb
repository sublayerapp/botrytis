class SessionsController < ApplicationController
  def new
    # Login form
  end

  def create
    # Simple authentication - just check if user exists
    if params[:email] == "test@example.com"
      session[:user_id] = 1
      redirect_to root_path, notice: "Successfully logged in!"
    else
      flash[:alert] = "Invalid credentials"
      render :new
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "Logged out!"
  end
end
