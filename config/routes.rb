Rails.application.routes.draw do
  root 'welcome#index'
  get 'auth/:provider/callback', to: 'sessions#create'
  get 'signout', to: 'sessions#destroy'

  get "/dashboard", to: "dashboard#index"
  post "/boards_creator", to: "boards_creator#create"

  resources :projects do
    resources :clones, only: [:new, :create]
  end
end