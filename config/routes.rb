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

  resource :leaderboard, only: [:show], controller: :leaderboard

  get :sign_in, to: "sessions#new"
  delete :sign_out, to: "sessions#destroy"

  root to: "leaderboard#show", constraints: AuthenticationConstraint
  root to: "sessions#new", as: nil

  # A simple health check for dokku
  get :health, to: proc { [200, {}, ['ok']] }
end
