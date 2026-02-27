# Personal dashboard for members (role: member).
# Admins are redirected to leagues_path — they don't use this.
class PlayersController < ApplicationController
  before_action :require_member!

  def show
    u = current_user
    @matches = Match.involving(u).recent.includes(:winner, :loser, :league)
    @stats = {
      total:   u.total_matches,
      wins:    u.wins_count,
      losses:  u.losses_count,
      win_pct: u.win_percentage,
      leagues: u.leagues.count
    }
  end

  private

  def require_member!
    # If an admin somehow lands here, send them to their panel
    redirect_to leagues_path if current_user.admin?
  end
end