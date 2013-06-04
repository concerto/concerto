Concerto::Application.routes.draw do
  resources :concerto_plugins
  match 'concerto_plugins/restart_for_plugin' => 'concerto_plugins#restart_for_plugin', :via => "post"
  
  resources :activities

  #Custom route for the screen creation/admin form JS
  #TODO(bamnet): Clean this up
  match "update_owners" => "screens#update_owners"

  # These routes control the frontend of Concerto used by screens.
  # You probably should not touch them without thinking very hard
  # about what you are doing because they could break things in
  # a very visible way.
  namespace :frontend do
    root :to => 'screen_auth#index'
    resources :screens, :only => [:show], :path => '' do
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
      :sessions => 'concerto_devise/sessions' }

  # Devise for screens allows devise to manage screen logins, but does
  # not provide any routes, as all authentication is managed by our own
  # controllers.
  devise_for :screens
  
  scope "/manage" do
    resources :users
  end

  resources :media, :only => [:show]

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
      resources :subscriptions do
        collection do
          get :manage
          put :save_all
        end
      end
    end
  end
  
  resources :groups do
    resources :memberships, :only => [:create, :update, :destroy] do     
    end
  end
  
  resources :kinds

  match "moderate/" => "feeds#moderate"

  resources :feeds do
    resources :submissions, :only => [:index, :show, :update]
  end

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

  #Set a non-restful route to the dashboard
  match 'dashboard/' => 'dashboard#index'
  match 'dashboard/run_backup' => 'dashboard#run_backup'
  match 'dashboard/update' => 'dashboard#update', :via => "post"
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get :short
  #       post :toggle
  #     end
  #
  #     collection do
  #       get :sold
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get :recent, :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # This is the catch-all path we use for people who type /content when they
  # are semantically looking for all the feeds to show the content.  We put it
  # here at the bottom to avoid capturing any of the restful content paths.
  match 'content/' => 'feeds#index'
  match 'browse/' => 'feeds#index'

  root :to => 'feeds#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
