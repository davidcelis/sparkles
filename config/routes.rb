Rails.application.routes.draw do
  root to: "slack/oauth#install"

  namespace :slack do
    resources :commands, only: [:create]

    namespace :oauth do
      get :install
      get :callback
    end
  end

  # A simple health check for dokku
  get :health, to: proc { [200, {}, ['ok']] }
end
