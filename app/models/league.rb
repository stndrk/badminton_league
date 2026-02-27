class League < ApplicationRecord
  belongs_to :owner, class_name: "User", foreign_key: :user_id, inverse_of: :owned_leagues

  has_many :memberships, dependent: :destroy
  has_many :members, through: :memberships, source: :user
  has_many :matches, dependent: :nullify    # matches survive league deletion (history preserved)

  validates :name, presence: true, uniqueness: { scope: :user_id, case_sensitive: false }

  normalizes :name, with: ->(n) { n.strip }

  def add_member(user, role: :member)
    memberships.find_or_create_by(user:) { |m| m.role = role }
  end

  def remove_member(user)
    memberships.find_by(user:)&.destroy
  end

  def ranked_members
    members.includes(:won_matches, :lost_matches).sort_by { |u| [ -u.win_percentage(self), -u.wins_count(self) ] }
  end
end
