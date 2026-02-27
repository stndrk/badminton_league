class MembershipsController < ApplicationController
  before_action :require_admin!
  before_action :set_league

  def create
    user = User.find(params[:user_id])
    membership = @league.add_member(user, role: :member)
    if membership.persisted?
      render json: { success: true, user: user.as_player_json(@league) }, status: :created
    else
      render json: { success: false, errors: membership.errors.full_messages },
             status: :unprocessable_entity
    end
  end

  def destroy
    user = User.find(params[:id])
    @league.remove_member(user)
    render json: { success: true }
  end

  private

  def set_league
    @league = League
                .where(user: current_user)
                .or(League.joins(:memberships).where(memberships: { user: current_user }))
                .find(params[:league_id])
  end
end