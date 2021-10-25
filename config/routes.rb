Rails.application.routes.draw do
  namespace :slack do
    resources :commands, only: [:create]
    resources :events, only: [:create]

    namespace :oauth do
      get :callback
    end

    namespace :openid do
      get :callback
    end
  end

  root to: "leaderboard#index", constraints: AuthenticationConstraint
  root to: "sessions#new", as: nil

  # A simple health check for dokku
  get :health, to: proc { [200, {}, ['ok']] }
end
