ActionController::Routing::Routes.draw do |map|
  
  ##########
  # Routes for Humans
  
  map.with_options :conditions => { :subdomain => false } do |map|
  end
  
  ##########
  # Routes for Nodes

  map.with_options :conditions => { :subdomain => 'service' } do |map|
    
    # User Routes
    map.with_options :controller => :user do |map|
      map.new_user '/user/new', :action => :new, :conditions => { :method => :post }
    end
    
    # Node Routes
    map.with_options :controller => :node do |map|
      map.new_node    '/node/new',    :action => :new,    :conditions => { :method => :post }
      map.update_node '/node/update', :action => :update, :conditions => { :method => :put }
    end
    
    # Message Routes
    map.with_options :controller => :message do |map|
      map.announce_message '/message/announce', :action => :announce, :conditions => { :method => :post }
    end
    
    # Tracker Routes
    map.with_options :controller => :asset do |map|
      map.announce_asset  '/tracker/asset/announce',  :action => :announce, :conditions => { :method => :post }
      map.activate_assets '/tracker/asset/activate',  :action => :activate, :conditions => { :method => :put }
      map.track_asset     '/tracker/asset/track',     :action => :track,    :conditions => { :method => :put }
    end
    
    # Test Routes
    # map.with_options :controller => :test do |map|
    #   map.new_test '/test/new', :action => :new
    # end
    
  end
  
  ##########
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
end
