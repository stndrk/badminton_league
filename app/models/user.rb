class User < ApplicationRecord
  include PlayerStats

  has_secure_password

  # super_admin REMOVED — only two roles: admin and member
  enum :role, { member: 0, admin: 1 }

  has_many :owned_leagues, class_name:  "League",
                           foreign_key: :user_id,
                           dependent:   :destroy,
                           inverse_of:  :owner

  has_many :memberships, dependent: :destroy
  has_many :leagues,     through:   :memberships

  normalizes :email, :name, with: ->(v) { v.strip }
  normalizes :email,        with: ->(e) { e.downcase }

  validates :name,  presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  # Full JSON — every field needed by modals and API consumers
  def as_player_json(league = nil)
    {
      id:           id,
      name:         name,
      email:        email,
      mobile:       mobile,
      dob:          dob&.strftime("%Y-%m-%d"),   # ISO for <input type="date">
      role:         role,
      wins:         wins_count(league),
      losses:       losses_count(league),
      total:        total_matches(league),
      win_pct:      win_percentage(league),
      member_since: created_at.strftime("%d %b %Y")
    }
  end
end
