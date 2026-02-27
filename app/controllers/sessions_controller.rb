class SessionsController < ApplicationController
  skip_before_action :require_login

  def new = render(:new)

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      # Role-based redirect:
      #   admin  → leagues index (full management panel)
      #   member → personal dashboard (read-only stats)
      destination = user.admin? ? leagues_path : player_path(user)
      redirect_to destination, notice: "Welcome, #{user.name}!"
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to new_session_path
  end
end
