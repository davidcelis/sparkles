Rails.application.routes.draw do
  namespace :slack do
    resources :commands, only: [:create]
  end
end
