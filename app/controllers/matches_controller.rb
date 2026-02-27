class MatchesController < ApplicationController
  before_action :set_match, only: %i[update destroy]

  # GET /matches                    — global admin dashboard (HTML)
  # GET /leagues/:league_id/matches — league match list (JSON via JS fetch)
  def index
    matches = (current_league&.matches || Match.global)
                .recent
                .includes(:winner, :loser, :league)

    if request.format.json? || current_league
      render json: matches.map(&:as_json_payload)
    else
      render template: "leagues/show"
    end
  end

  def create
    require_admin! and return unless current_user.admin?
    @match = Match.new(match_params.merge(league: match_league))
    if @match.save
      render json: { success: true, match: @match.as_json_payload }, status: :created
    else
      render_errors(@match)
    end
  end

  def update
    require_admin! and return unless current_user.admin?
    if @match.update(match_params)
      render json: { success: true, match: @match.as_json_payload }
    else
      render_errors(@match)
    end
  end

  def destroy
    require_admin! and return unless current_user.admin?
    @match.destroy
    render json: { success: true }
  end

  private

  def set_match
    scope  = current_league&.matches || Match.all
    @match = scope.find(params[:id])
  end

  def match_league
    lid = match_params[:league_id].presence || current_league&.id
    lid ? League.find_by(id: lid) : nil
  end

  def match_params = params.require(:match).permit(:winner_id, :loser_id, :league_id)
end