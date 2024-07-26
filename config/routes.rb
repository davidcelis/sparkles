Rails.application.routes.draw do
  root "pages#index"

  namespace :slack do
    resources :commands, only: :create
    resources :events, only: :create

    namespace :oauth do
      get :callback
    end
  end

  get "terms" => "pages#terms", :as => :terms
  get "privacy" => "pages#privacy", :as => :privacy

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check
end
