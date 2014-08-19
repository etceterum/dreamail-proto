ActionController::Routing::Routes.draw do |map|
  # map.resources :in_attachments

  # map.resources :in_messages, :collection => { :select => :post }
  # map.resources :out_messages

  # map.attachment '/attachment/:id', :controller => :in_messages, :action => :download, :conditions => { :method => :get }
  # map.incoming_message 'message/incoming/:id', :controller => :in_messages, :action => :show, :conditions => { :method => :get }
  
  map.with_options :controller => :human do |map|
    map.refresh '/refresh', :action => :refresh, :conditions => { :method => :get }
    map.trash '/trash', :action => :trash, :conditions => { :method => :get }
  end
  
  map.with_options :controller => :in_messages do |map|
    map.inbox '/inbox', :action => :index, :conditions => { :method => :get }
    map.embed_in_message_content '/message/incoming/embed/content/:id', :action => :embed_content, :conditions => { :method => :get }
    map.embedded_in_message '/message/incoming/embed/:id', :action => :embed, :conditions => { :method => :get }
    map.in_message_header '/message/incoming/header/:id', :action => :header, :conditions => { :method => :get }
    map.in_message_list '/message/incoming/list', :action => :list
    map.in_message '/message/incoming/:id', :action => :show, :conditions => { :method => :get }
  end
  
  map.with_options :controller => :in_attachments do |map|
    map.open_in_attachment '/attachment/incoming/open/:id', :action => :open, :conditions => { :method => :get }
    map.download_in_attachment '/attachment/incoming/download/:id', :action => :download, :conditions => { :method => :put }
    map.ready_in_attachment '/attachment/incoming/ready/:id', :action => :ready, :conditions => { :method => :get }
    map.in_attachments_downloads '/downloads', :action => :downloads, :conditions => { :method => :get }
    map.in_attachments_downloads '/downloads/list', :action => :downloads_list, :conditions => { :method => :get }
  end
  
  map.with_options :controller => :out_messages do |map|
    map.new_draft '/draft/new', :action => :new
    map.create_draft '/draft/create', :action => :create, :conditions => { :method => :post }
    map.edit_draft '/draft/edit/:id', :action => :edit, :conditions => { :method => :get }
    map.update_draft '/draft/update/:id', :action => :update, :conditions => { :method => :put }
    # map.embed_draft_content '/draft/embed/content/:id', :action => :embed_draft_content, :conditions => { :method => :get }
    map.embed_draft '/draft/embed/:id', :action => :embed_draft, :conditions => { :method => :get }
    map.drafts '/drafts', :action => :drafts, :conditions => { :method => :get }
    map.unsent '/outbox', :action => :unsent, :conditions => { :method => :get }
    map.unsent_list '/outbox/list', :action => :unsent_list
    map.sent '/sent', :action => :sent, :conditions => { :method => :get }
    map.sent_list '/sent/list', :action => :sent_list
    map.embed_outgoing_content '/message/outgoing/embed/content/:id', :action => :embed_content, :conditions => { :method => :get }
    map.embed_outgoing '/message/outgoing/embed/:id', :action => :embed, :conditions => { :method => :get }
  end
  
  map.with_options :controller => :contacts do |map|
    map.contacts '/contacts', :action => :index, :conditions => { :method => :get }
    map.autocomplete '/contacts/autocomplete', :action => :autocomplete, :conditions => { :method => :get }
  end
  
  map.with_options :controller => :filesystem do |map|
    map.filesystem_ls '/filesystem/ls', :action => :ls, :conditions => { :method => :post }
    map.filesystem_tree '/filesystem/tree', :action => :tree, :conditions => { :method => :get }
  end

  map.with_options :controller => :download do |map|
    map.download '/service/download', :action => :piece, :conditions => { :method => :get }
  end
  
  map.root :controller => :human

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
