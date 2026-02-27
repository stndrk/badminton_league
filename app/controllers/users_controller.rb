class UsersController < ApplicationController
  before_action :require_admin!
  before_action :set_user, only: %i[show update destroy]

  # GET /users — JSON list of all members (admin only)
  def index
    users = User.where(role: :member).includes(:won_matches, :lost_matches).order(:name)
    render json: users.map(&:as_player_json)
  end

  # GET /users/:id — full JSON for edit modal pre-fill
  def show
    render json: @user.as_player_json
  end

  # POST /users — admin creates a new player (always role: member)
  def create
    @user = User.new(user_params.merge(role: :member))
    if @user.save
      render json: { success: true, user: @user.as_player_json }, status: :created
    else
      render_errors(@user)
    end
  end

  # PATCH /users/:id
  def update
    if @user.update(user_params)
      render json: { success: true, user: @user.as_player_json }
    else
      render_errors(@user)
    end
  end

  # DELETE /users/:id
  def destroy
    if @user == current_user
      render json: { success: false, errors: ["Cannot delete yourself"] },
             status: :unprocessable_entity
      return
    end
    @user.destroy
    render json: { success: true }
  end

  private

  def set_user = @user = User.find(params[:id])

  def user_params
    allowed = %i[name email mobile dob]
    allowed += %i[password password_confirmation] if params.dig(:user, :password).present?
    params.require(:user).permit(*allowed)
  end
end