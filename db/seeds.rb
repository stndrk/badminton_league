# db/seeds.rb
# ═══════════════════════════════════════════════════
# Badminton League — Seed Data
# rails db:seed          → adds seed data
# rails db:seed:replant  → wipes then reseeds (Rails 6+)
# ═══════════════════════════════════════════════════

puts "\n🏸  Seeding Badminton League...\n#{"─" * 42}"

Match.destroy_all
Membership.destroy_all
League.destroy_all
User.destroy_all

puts "✓  Cleared existing data"

# ── Admin ──────────────────────────────────────────
admin = User.create!(
  name:                  "Rahul Sharma",
  email:                 "admin@badminton.org.com",
  password:              "password123",
  password_confirmation: "password123",
  role:                  :admin
)
puts "✓  Admin created  →  #{admin.email}"

# ── Players (role: member) ─────────────────────────
players_data = [
  { name: "Arjun Mehta",    email: "arjun@badminton.org.com",   mobile: "9810001001", dob: "1995-03-12" },
  { name: "Sneha Patel",    email: "sneha@badminton.org.com",   mobile: "9810001002", dob: "1997-07-22" },
  { name: "Vikram Singh",   email: "vikram@badminton.org.com",  mobile: "9810001003", dob: "1993-11-05" },
  { name: "Kavya Reddy",    email: "kavya@badminton.org.com",   mobile: "9810001004", dob: "1999-01-30" },
  { name: "Rohit Gupta",    email: "rohit@badminton.org.com",   mobile: "9810001005", dob: "1994-06-18" },
  { name: "Ananya Das",     email: "ananya@badminton.org.com",  mobile: "9810001006", dob: "1998-09-14" },
  { name: "Karan Malhotra", email: "karan@badminton.org.com",   mobile: "9810001007", dob: "1996-04-25" },
  { name: "Divya Iyer",     email: "divya@badminton.org.com",   mobile: "9810001008", dob: "1992-12-08" },
]

players = players_data.map do |pd|
  User.create!(
    name:                  pd[:name],
    email:                 pd[:email],
    mobile:                pd[:mobile],
    dob:                   pd[:dob],
    password:              "password123",
    password_confirmation: "password123",
    role:                  :member
  )
end
puts "✓  #{players.size} players created"

# ── Leagues ────────────────────────────────────────
office   = League.create!(name: "Office Smash Cup 2025",  user_id: admin.id)
weekend  = League.create!(name: "Weekend Warriors",       user_id: admin.id)
open_cup = League.create!(name: "Open Championship",      user_id: admin.id)
puts "✓  3 leagues created"

# ── Memberships ────────────────────────────────────
# All leagues get the admin as league-admin
[office, weekend, open_cup].each { |l| l.add_member(admin, role: :admin) }

# Office league — all 8 players
players.each { |p| office.add_member(p) }

# Weekend Warriors — first 5 players
players.first(5).each { |p| weekend.add_member(p) }

# Open Championship — all 8 players
players.each { |p| open_cup.add_member(p) }

puts "✓  Memberships created"

# ── Match helper ───────────────────────────────────
def make_match(league, winner, loser, days_ago)
  Match.create!(
    league:     league,
    winner:     winner,
    loser:      loser,
    created_at: days_ago.days.ago,
    updated_at: days_ago.days.ago
  )
end

# ── Office league matches (20) ─────────────────────
[
  [0,1],[2,3],[4,5],[6,7],[0,2],[1,3],
  [4,6],[5,7],[0,3],[2,4],[1,5],[3,6],
  [0,4],[2,6],[1,7],[3,5],[0,6],[1,4],
  [2,7],[5,6]
].each_with_index do |(w,l), i|
  make_match(office, players[w], players[l], 25 - i)
end
puts "✓  #{office.matches.count} matches → #{office.name}"

# ── Weekend Warriors matches (10) ─────────────────
[
  [0,1],[2,3],[4,0],[1,2],[3,4],
  [0,3],[2,4],[1,4],[0,2],[3,1]
].each_with_index do |(w,l), i|
  make_match(weekend, players[w], players[l], 14 - i)
end
puts "✓  #{weekend.matches.count} matches → #{weekend.name}"

# ── Open Championship matches (15) ────────────────
[
  [0,7],[1,6],[2,5],[3,4],[0,5],
  [1,4],[2,7],[3,6],[0,3],[1,2],
  [4,7],[5,6],[0,2],[1,7],[3,5]
].each_with_index do |(w,l), i|
  make_match(open_cup, players[w], players[l], 18 - i)
end
puts "✓  #{open_cup.matches.count} matches → #{open_cup.name}"

# ── Friendly / global matches (no league) ─────────
[
  [0,1],[2,3],[4,5],[6,7],[0,5],[2,7]
].each_with_index do |(w,l), i|
  Match.create!(
    league:     nil,
    winner:     players[w],
    loser:      players[l],
    created_at: (8 - i).days.ago,
    updated_at: (8 - i).days.ago
  )
end
puts "✓  #{Match.where(league: nil).count} friendly (no-league) matches"

# ── Summary ────────────────────────────────────────
puts "\n#{"═" * 42}"
puts "🏸  Seed complete!"
puts "#{"═" * 42}"
puts "  Users       : #{User.count}  (1 admin, #{User.member.count} players)"
puts "  Leagues     : #{League.count}"
puts "  Memberships : #{Membership.count}"
puts "  Matches     : #{Match.count}  (#{Match.where(league: nil).count} friendly)"
puts ""
puts "  Login credentials  (password: password123)"
puts "  ┌──────────────────────────────────────────"
puts "  │  Admin    admin@badminton.org.com"
puts "  │  Players  arjun / sneha / vikram / kavya"
puts "  │           rohit / ananya / karan / divya"
puts "  │           (all @badminton.org.com)"
puts "  └──────────────────────────────────────────\n\n"