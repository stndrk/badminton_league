class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :league

  enum :role, { member: 0, admin: 1 }

  validates :user_id, uniqueness: { scope: :league_id, message: "is already in this league" }
end
