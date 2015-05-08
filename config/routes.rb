ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.


  map.connect ':controller/get_file', :action => 'get_file'
  # custom route for search on each controller
  map.connect ':controller/search', :action => 'search'
  map.connect ':controller/upload', :action => 'upload'
  # named routes
  map.resource :mhc
  map.resources :offline_suppressions
  map.resources  :task_status
  map.resources :roles
  map.namespace :admin do |admin|
    admin.resources :roles, :except=> :show
  end

  map.resources :roles_groups
  map.namespace :admin do |admin|
    admin.resources :roles_groups
  end
  map.resources :orgs
  map.namespace :admin do |admin|
    admin.resources :orgs
    admin.resources :hip_configs
    admin.resources :task_statuses,:as=>:tasks
  end

  map.admin_cbn '/admin/cbn', :controller => 'admin/cbn', :action => 'index'


  #custom routes for non-account related roles
  map.connect '/admin/roles_groups/edit2/:id', :controller => 'admin/roles_groups', :action =>:edit2
  map.connect '/admin/roles_groups/update2/:id', :controller => 'admin/roles_groups', :action =>:update2
  map.connect '/admin/roles_groups/create2/:id', :controller => 'admin/roles_groups', :action =>:create2

#04-17-2013 routes for hipreset
 #map.connect '/out_of_cycle/dashboard/:id', :controller => 'out_of_cycle/dashboard/hipreset_counts', :action => 'show'

  map.resources :hc_groups
  map.resources :suppressions
  map.resources :vulns
  map.resources :dashboard
  map.resources :hc_cycle_group_dashboard
  map.resources :missed_scans
  map.resources :scans # incycle scan
  map.resources :publish_scans
  map.resources :deviations
  map.resources :validation_groups
  map.namespace :out_of_cycle do |out|
    out.resources(:ooc_groups,:controller=>:groups)
    out.resources(:assets)
    out.resource(:scans)
    out.resource(:missed_scans)
    out.resource(:deviations)
    out.resource(:release_scans)
    out.resource(:dashboard)
    out.resources(:hip_reset_counts)
    out.resource(:validation_groups)
    out.resource(:copy_groups)
    out.resource(:dashboard)
    out.resources :offline_suppressions
    out.namespace :reports do |report|
      report.resource(:final_ooc_reports)
      report.resource(:interim_reports)
    end
  end
  #map.resources :reports
  map.namespace :reports do |report|
    report.resource(:interim_reports) #for nested controller
    report.resource(:cycle_end_reports)
    report.resource(:out_of_cycle_reports)
    report.resource(:amer_geo_reports)
  end
  
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
  map.root :controller => "home"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
