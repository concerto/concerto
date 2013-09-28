class LegacyRouteMatcher
  # Catch requests that have a 'mac' parameter.
  def matches?(request)
    return !request.query_parameters[:mac].nil?
  end
end

Concerto::Application.routes.draw do
  v1_router = LegacyRouteMatcher.new
  get '/' => 'frontend/screens#index', :constraints => v1_router
  get '/screen' => 'frontend/screens#index', :constraints => v1_router, :as => 'legacy_frontend'

  root :to => 'feeds#index'

  resource :dashboard, :controller => :dashboard, :only => [:show] do
    get :list_activities
  end

  resources :concerto_plugins
  post 'concerto_plugins/restart_for_plugin' => 'concerto_plugins#restart_for_plugin'

  resources :activities

  #Custom route for the screen creation/admin form JS
  #TODO(bamnet): Clean this up
  get "update_owners" => "screens#update_owners"

  # These routes control the frontend of Concerto used by screens.
  # You probably should not touch them without thinking very hard
  # about what you are doing because they could break things in
  # a very visible way.
  namespace :frontend do
    resources :screens, :only => [:show, :index], :path => '' do
      member do
        get :setup
      end
      resources :fields, :only => [] do
        resources :contents, :only => [:index, :show]
      end
      resources :templates, :only => [:show]
    end
  end
  # End really dangerous routes.


  devise_for :users,
             :controllers => {
               :registrations => 'concerto_devise/registrations',
               :sessions => 'concerto_devise/sessions'}

  scope "/manage" do
    resources :users
  end

  resources :media, :only => [:show, :create ]

  resources :templates do
    member do
      get :preview
    end
    collection do
      post :import
    end
  end

  resources :screens do
    resources :fields, :only => [] do
      resources :subscriptions
      resources :field_configs
    end
  end

  resources :groups, :except => [:edit] do
    resources :memberships, :only => [:create, :update, :destroy] do
    end
  end

  resources :kinds

  resources :feeds do
    collection do
      get :moderate
    end
    resources :submissions, :only => [:index, :show, :update]
  end

  get 'content/search' => 'contents#index'
  resources :contents, :except => [:index], :path => "content" do
    member do
      get :display
      put :act
    end
    collection do
      post :preview
    end
  end

  # TODO(bamnet): Figure out if these routes mean anything.
  resources :graphics, :controller => :contents, :except => [:index, :show], :path => "content" do
    get :display, :on => :member
  end

  resources :tickers, :controller => :contents, :except => [:index, :show], :path => "content"
  resources :html_texts, :controller => :contents, :except => [:index, :show], :path => "content"
  resources :client_times, :controller => :contents, :except => [:index, :show], :path => "content"

  resource :concerto_config, :controller => :concerto_config, :only => [:show, :update], :path => "settings"

  # This is the catch-all path we use for people who type /content when they
  # are semantically looking for all the feeds to show the content.  We put it
  # here at the bottom to avoid capturing any of the restful content paths.
  get 'content/' => 'feeds#index'
  get 'browse/' => 'feeds#index'

  unless Rails.application.config.consider_all_requests_local
    get '*not_found', :to => 'errors#error_404'
  end

end
