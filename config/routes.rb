Rails.application.routes.draw do
  namespace :frontend do
    resources :screens, only: [ :show ]
    get "/screens/:screen_id/fields/:field_id/content/", to: "content#index", as: "content"

    # The main landing page for the frontend player.
    get "/:id", to: "player#show", as: "player"
  end
  resources :screens do
    resources :subscriptions, only: [ :index, :create, :destroy ]
  end
  resources :templates
  resources :submissions
  resources :rss_feeds
  resources :feeds
  resources :rich_texts
  resources :graphics
  resources :contents, only: [ :index, :new ]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
