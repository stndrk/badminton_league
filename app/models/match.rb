class Match < ApplicationRecord
  belongs_to :league, optional: true
  belongs_to :winner, class_name: "User", inverse_of: :won_matches
  belongs_to :loser,  class_name: "User", inverse_of: :lost_matches

  scope :recent,     -> { order(created_at: :desc) }
  scope :global,     -> { where(league: nil) }
  scope :for_league, ->(league) { where(league:) }

  # All matches involving a specific user (as winner or loser)
  scope :involving, ->(user) {
    where(winner: user).or(where(loser: user))
  }

  validate :different_players
  validate :players_are_league_members, if: :league_id?

  # Standard payload for admin views (lists, edit pre-fill)
  def as_json_payload
    {
      id:        id,
      winner:    winner.name,
      winner_id: winner_id,
      loser:     loser.name,
      loser_id:  loser_id,
      league:    league&.name || "Friendly",
      league_id: league_id,
      date:      created_at.strftime("%d %b %Y")
    }
  end

  # Player-perspective payload — shows result from that player's point of view
  def as_match_json_for(user)
    won = winner_id == user.id
    {
      id:       id,
      result:   won ? "Win" : "Loss",
      opponent: won ? loser.name : winner.name,
      league:   league&.name || "Friendly",
      date:     created_at.strftime("%d %b %Y")
    }
  end

  private

  def different_players
    errors.add(:base, "Winner and loser must be different") if winner_id == loser_id
  end

  def players_are_league_members
    league_member_ids = league.memberships.pluck(:user_id).to_set
    [ winner_id, loser_id ].each do |uid|
      unless league_member_ids.include?(uid)
        errors.add(:base, "Player #{uid} is not a member of this league")
      end
    end
  end
end
