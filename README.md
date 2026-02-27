# README

# 🏸 Badminton League

A monolithic Rails application for managing badminton leagues — track players, record matches, and view live standings.

---

## Tech Stack

| Layer     | Technology               |
| --------- | ------------------------ |
| Framework | Ruby on Rails 8.0.4      |
| Database  | PostgreSQL (or SQLite)   |
| Auth      | `has_secure_password`    |
| Frontend  | ERB + Vanilla JS (fetch) |
| CSS       | Custom (CSS variables)   |
| Fonts     | Bebas Neue + Outfit      |
| Icons     | Bootstrap Icons CDN      |

---

## Project Setup

```bash
# 1. Clone and enter project
git clone <repo-url>
cd badminton_league

# 2. Install dependencies
bundle install

# 3. Setup database
rails db:create db:migrate db:seed

# 4. Start the server
rails server
# → open http://localhost:3000
```

**Seed credentials** (password: `password123`)

| Role   | Email                    |
| ------ | ------------------------ |
| Admin  | admin@badminton.org.com  |
| Player | arjun@badminton.org.com  |
| Player | sneha@badminton.org.com  |
| Player | vikram@badminton.org.com |
| Player | kavya@badminton.org.com  |
| Player | rohit@badminton.org.com  |
| Player | ananya@badminton.org.com |
| Player | karan@badminton.org.com  |
| Player | divya@badminton.org.com  |

---

## File & Directory Structure

```
badminton_league/
│
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb   # auth, current_user, current_league helpers
│   │   ├── sessions_controller.rb      # login / logout
│   │   ├── players_controller.rb       # member personal stats view
│   │   ├── leagues_controller.rb       # admin: CRUD leagues + leaderboard JSON
│   │   ├── matches_controller.rb       # admin: CRUD matches + global dashboard
│   │   ├── users_controller.rb         # admin: CRUD players (JSON API)
│   │   └── memberships_controller.rb   # admin: add/remove league members
│   │
│   ├── models/
│   │   ├── concerns/
│   │   │   └── player_stats.rb         # wins_count, losses_count, win_percentage
│   │   ├── user.rb                     # User = Player (merged). Roles: admin | member
│   │   ├── match.rb                    # winner_id, loser_id, league_id (nullable)
│   │   ├── league.rb                   # name, owner (user_id)
│   │   └── membership.rb              # join: user ↔ league, with role
│   │
│   └── views/
│       ├── layouts/
│       │   └── application.html.erb    # base layout (fonts, Bootstrap, flash)
│       ├── sessions/
│       │   └── new.html.erb            # login page
│       ├── players/
│       │   └── show.html.erb           # member personal stats & match history
│       ├── leagues/
│       │   ├── index.html.erb          # admin: list leagues + create form
│       │   └── show.html.erb           # admin: full dashboard (players, matches, rankings)
│       └── matches/
│           └── index.html.erb          # placeholder (controller renders leagues/show)
│
├── config/
│   └── routes.rb
│
└── db/
    ├── migrate/
    │   └── xxx_create_core_schema.rb
    └── seeds.rb
```

---

## Database Schema

### `users`

| Column          | Type     | Notes                          |
| --------------- | -------- | ------------------------------ |
| id              | integer  | PK                             |
| name            | string   | required                       |
| email           | string   | required, unique, downcased    |
| password_digest | string   | bcrypt via has_secure_password |
| role            | integer  | enum: `member: 0`, `admin: 1`  |
| mobile          | string   | optional                       |
| dob             | date     | optional                       |
| created_at      | datetime |                                |

**Why User = Player?**
A separate `Player` model would duplicate `name`, `email`, and auth fields. Since every player must log in, they are the same entity. One model = no sync problems, no N+1 join just to display a name.

### `leagues`

| Column     | Type     | Notes                      |
| ---------- | -------- | -------------------------- |
| id         | integer  | PK                         |
| name       | string   | required, unique per user  |
| user_id    | integer  | FK → users (owner/creator) |
| created_at | datetime |                            |

### `memberships`

| Column     | Type     | Notes                                      |
| ---------- | -------- | ------------------------------------------ |
| id         | integer  | PK                                         |
| user_id    | integer  | FK → users                                 |
| league_id  | integer  | FK → leagues                               |
| role       | integer  | enum: `member: 0`, `admin: 1` (per-league) |
| created_at | datetime |                                            |

_Unique index on `[user_id, league_id]` — DB prevents duplicate membership._

**Why a join table instead of `has_many :players`?**
The `Membership` table carries a `role` column (who's admin within this league), a timestamp (when they joined), and enforces the unique constraint at the database level. You can later add `elo_rating`, `invited_by`, `status` as columns here without changing `User` or `League`. It's the primary scalability point in the schema.

### `matches`

| Column     | Type     | Notes                                       |
| ---------- | -------- | ------------------------------------------- |
| id         | integer  | PK                                          |
| winner_id  | integer  | FK → users (NOT NULL)                       |
| loser_id   | integer  | FK → users (NOT NULL)                       |
| league_id  | integer  | FK → leagues, **nullable** (friendly match) |
| created_at | datetime |                                             |

**Why is `league_id` nullable?**
Making it required means you can't record a match until league admin structure is set up. Nullable lets the app serve two use cases from one table: official league matches and friendly/global matches between any two players.

**Why named foreign keys (`winner_id`, `loser_id`) instead of polymorphic?**
The DB enforces referential integrity on both sides. You can never record a match where the winner doesn't exist. The intent is also clear from the schema — no ambiguity about what type of record these FKs point to.

---

## Associations
![Login Page Screenshot](https://raw.githubusercontent.com/stndrk/badminton_league/main/public/associations.png)

---

## Role System

| Role   | Can Do                                                                              |
| ------ | ----------------------------------------------------------------------------------- |
| admin  | Create leagues, add/remove players, record/edit/delete matches, view all dashboards |
| member | Log in, view personal stats page (matches, wins, losses, win rate, leagues)         |

**After login redirect:**

- `admin` → `/leagues` (full management panel)
- `member` → `/dashboard` (personal read-only stats)

---

## Key Architectural Decisions

### Monolithic, server-rendered with a JSON API layer

The app uses ERB for page structure and a thin JSON API (fetch calls) for dynamic table data within those pages. This gives you fast initial page loads without a separate frontend framework, while still keeping the UI interactive.

### Single dashboard template (`leagues/show.html.erb`)

Both `/leagues/:id` (league context) and `/matches` (global context) render the same template. The JS reads `leagueId` from a server-rendered JSON island (`<script type="application/json">`) and adjusts all API calls accordingly. `null` leagueId = global context.

### JSON islands over ERB in `<script>` tags

All server data the JS needs is embedded once in `<script id="__app__" type="application/json">`. This avoids ERB inside JavaScript strings (which causes escaping bugs and goes stale on dynamic updates) and is XSS-safe because the browser never executes `application/json` script tags.

### `PlayerStats` concern with optional league scope

`wins_count`, `losses_count`, and `win_percentage` all accept an optional `league` argument. The same methods power both the global leaderboard (`/users`) and the per-league rankings (`/leagues/:id/leaderboard`) without any code duplication.

---

## API Endpoints

| Method | Path                         | Action                    | Role   |
| ------ | ---------------------------- | ------------------------- | ------ |
| GET    | /dashboard                   | Member personal stats     | member |
| GET    | /leagues                     | Admin leagues list        | admin  |
| POST   | /leagues                     | Create league             | admin  |
| GET    | /leagues/:id                 | Admin dashboard           | admin  |
| GET    | /leagues/:id/leaderboard     | Rankings JSON             | admin  |
| GET    | /users                       | Players list JSON         | admin  |
| GET    | /users/:id                   | Single player JSON        | admin  |
| POST   | /users                       | Create player             | admin  |
| PATCH  | /users/:id                   | Update player             | admin  |
| DELETE | /users/:id                   | Delete player             | admin  |
| GET    | /matches                     | Global dashboard HTML     | admin  |
| POST   | /matches                     | Create global match       | admin  |
| POST   | /leagues/:id/matches         | Create league match       | admin  |
| PATCH  | /matches/:id                 | Update match              | admin  |
| DELETE | /matches/:id                 | Delete match              | admin  |
| POST   | /leagues/:id/memberships     | Add player to league      | admin  |
| DELETE | /leagues/:id/memberships/:id | Remove player from league | admin  |

---

## Future Scaling Points

- **ELO ratings** — add `elo` integer to `Membership` table, update on each match
- **Match sets/scores** — add `score_winner`, `score_loser` to `matches`
- **Tournaments** — add a `Tournament` model that `belongs_to :league`, `has_many :matches`
- **Notifications** — `after_create` callback on `Match` → email/push to participants
- **API tokens** — add `api_token` to `User` for mobile app integration
- **Multi-sport** — add `sport` enum to `League` to reuse the entire stack for tennis, table tennis, etc.

* ...

## Images

![Login Page Screenshot](https://raw.githubusercontent.com/stndrk/badminton_league/main/public/login_page.png)

![Page After Login Screenshot](https://raw.githubusercontent.com/stndrk/badminton_league/main/public/leagues_after_login.png)

![Leaderboard Page Screenshot](https://raw.githubusercontent.com/stndrk/badminton_league/main/public/leaderboard.png)

![Players Page Screenshot](https://raw.githubusercontent.com/stndrk/badminton_league/main/public/players.png)

![Matches Page Screenshot](https://raw.githubusercontent.com/stndrk/badminton_league/main/public/matches.png)
