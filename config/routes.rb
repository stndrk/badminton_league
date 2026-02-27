Rails.application.routes.draw do
  root "sessions#new"

  resource  :session, only: %i[new create destroy]
  resources :users,   only: %i[index show create update destroy]
  resources :matches, only: %i[index create update destroy]
  resources :players, only: %i[show]

  resources :leagues, only: %i[index new create show destroy] do
    get :leaderboard, on: :member
    resources :matches,     only: %i[index create update destroy]
    resources :memberships, only: %i[create destroy]
  end
end
