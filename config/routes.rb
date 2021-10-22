Rails.application.routes.draw do
  namespace :slack do
    resources :commands, only: [:create]

    namespace :oauth do
      get :install
      get :callback
    end
  end

  root to: "slack/oauth#install"
end
