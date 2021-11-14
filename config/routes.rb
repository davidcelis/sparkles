Rails.application.routes.draw do
  namespace :slack do
    resources :commands, only: [:create]
    resources :events, only: [:create]
    resources :interactions, only: [:create]

    namespace :oauth do
      get :callback
    end

    namespace :openid do
      get :callback
    end
  end

  get "/stats/:slack_team_id", to: "stats#team", as: :team_stats
  get "/stats/:slack_team_id/:slack_user_id", to: "stats#user", as: :user_stats

  root to: "pages#welcome"
  delete :sign_out, to: "sessions#destroy"

  # A simple health check for dokku
  get :health, to: proc { [200, {}, ["ok"]] }
end
