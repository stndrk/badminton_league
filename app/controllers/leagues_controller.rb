class LeaguesController < ApplicationController
  before_action :require_admin!
  before_action :set_league, only: %i[show destroy leaderboard]

  # GET /leagues
  def index
    @leagues = League
                 .left_joins(:memberships)
                 .where("leagues.user_id = :id OR memberships.user_id = :id", id: current_user.id)
                 .distinct
                 .includes(:owner, :members, :matches)
                 .order(:name)
  end

  # GET /leagues/new  (not used as a separate page — kept for completeness)
  def new = render(:new)

  # POST /leagues
  def create
    @league = current_user.owned_leagues.build(league_params)
    if @league.save
      @league.add_member(current_user, role: :admin)
      redirect_to league_path(@league), notice: "#{@league.name} created!"
    else
      @leagues = League
                   .where(user: current_user)
                   .or(League.joins(:memberships).where(memberships: { user: current_user }))
                   .distinct.includes(:owner, :members, :matches).order(:name)
      flash.now[:alert] = @league.errors.full_messages.to_sentence
      render :index, status: :unprocessable_entity
    end
  end

  # GET /leagues/:id — full admin dashboard
  def show
    @league.members.includes(:won_matches, :lost_matches).load
  end

  # GET /leagues/:id/leaderboard — JSON for JS fetch, sorted by win %
  def leaderboard
    stats = @league
              .members
              .includes(:won_matches, :lost_matches)
              .sort_by { |u| [ -u.win_percentage(@league), -u.wins_count(@league) ] }
              .map { |u| u.as_player_json(@league) }
    render json: stats
  end

  def destroy
    @league.destroy
    redirect_to leagues_path, notice: "League deleted."
  end

  private

  def set_league
    @league = League
                .where(user: current_user)
                .or(League.joins(:memberships).where(memberships: { user: current_user }))
                .find(params[:id])
  end

  def league_params = params.require(:league).permit(:name)
end
