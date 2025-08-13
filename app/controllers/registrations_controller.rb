# app/controllers/registrations_controller.rb
class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(user_params)
    
    if @user.save
      session = @user.sessions.create!
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true }
      
      redirect_to root_path, notice: "Welcome! You have signed up successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end