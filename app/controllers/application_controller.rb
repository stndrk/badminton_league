class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def require_login
    redirect_to new_session_path, alert: "Please log in." unless current_user
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def current_league
    return nil unless params[:league_id]
    @current_league ||= League
                          .where(user: current_user)
                          .or(League.joins(:memberships).where(memberships: { user: current_user }))
                          .find(params[:league_id])
  end
  helper_method :current_league

  def require_admin!
    return if current_user.admin?
    respond_to do |fmt|
      fmt.json { render json: { error: "Not authorized" }, status: :forbidden }
      fmt.html { redirect_to players_path, alert: "Not authorized." }
    end
  end

  def render_errors(model, status: :unprocessable_entity)
    render json: { success: false, errors: model.errors.full_messages }, status:
  end
end