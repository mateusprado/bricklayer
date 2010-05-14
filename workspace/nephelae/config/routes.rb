ActionController::Routing::Routes.draw do |map|

  map.with_options :controller => :admin do |u|
    u.admin '/admin', :action => :index
  end
  
  map.namespace :admin do |admin|
    admin.resources :zones
    admin.resources :accounts, :member => {:access => :put}
    admin.resources :processing_errors, :member => {:retry => :put}
    admin.resources :virtual_machines
  end

  map.with_options :controller => 'machines' do |u|
    u.step1 '/machines/wizard', :action => 'wizard'
    u.confirm_run_virtual_machine 'machines/:id/run/:command/confirm', :action => :confirm_run
    u.connect 'machines/:id/run/:command/confirmed', :action => :run
  end

  map.resources :virtual_machines,
    :as => :machines,
    :controller => 'machines',
    :member => {:wizard => :get, :run => :put} do |r|
      r.resources :firewall_rules, :member => {:remove => :get}
      r.resources :snapshots, :member => {:remove => :get, :revert => :put}
      r.resources :console
  end

  map.with_options :controller => :console do |c|
    c.virtual_machine_console 'machines/:virtual_machine_id/console', :action => :index
  end
  
  map.with_options :controller => :firewall_rules do |u|
    u.connect 'machines/:virtual_machine_id/firewall_rules/:id/remove/confirmed', :action => :destroy
  end
  
  map.with_options :controller => :snapshots do |u|
    u.connect 'machines/:virtual_machine_id/snapshots/:id/remove/confirmed', :action => :destroy
    u.confirm_revert_virtual_machine_snapshot 'machines/:virtual_machine_id/snapshots/:id/revert/confirm', :action => :confirm_revert
    u.connect 'machines/:virtual_machine_id/snapshots/:id/revert/confirmed', :action => :revert
  end

  map.root :controller => 'dashboard'
  map.logout '/logout', :controller => 'dashboard', :action => 'logout'
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
