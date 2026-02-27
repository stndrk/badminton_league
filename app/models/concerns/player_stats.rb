module PlayerStats
  extend ActiveSupport::Concern

  included do
    has_many :won_matches,  class_name: "Match", foreign_key: :winner_id, inverse_of:  :winner, dependent:   :nullify
    has_many :lost_matches, class_name: "Match", foreign_key: :loser_id, inverse_of:  :loser, dependent:   :nullify
  end

  # Pass a league to scope stats to that league, nil = global
  def wins_count(league = nil)
    rel = won_matches
    rel = rel.where(league: league) if league
    rel.size
  end

  def losses_count(league = nil)
    rel = lost_matches
    rel = rel.where(league: league) if league
    rel.size
  end

  def total_matches(league = nil)
    wins_count(league) + losses_count(league)
  end

  def win_percentage(league = nil)
    total = total_matches(league)
    return 0.0 if total.zero?
    (wins_count(league).to_f / total * 100).round(1)
  end
end
