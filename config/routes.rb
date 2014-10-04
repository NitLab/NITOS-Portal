Rails.application.routes.draw do
  resources :users
  resources :sessions, only: [:new, :create, :destroy]

  root  'static_pages#home'
  match '/signup',                to: 'users#new',                      via: 'get'
  match '/signin',                to: 'sessions#new',                   via: 'get'
  match '/signout',               to: 'sessions#destroy',               via: 'delete'
  match '/your_ssh_keys',         to: 'static_pages#your_ssh_keys',     via: 'get'
  match '/about',                 to: 'static_pages#about',             via: 'get'
  match '/node_status',           to: 'node_status#node_status',        via: 'get'
  match '/scheduler',             to: 'scheduler#scheduler',            via: 'get'
  match '/reservation',           to: 'scheduler#reservation',          via: 'get'
  match '/my_reservations',       to: 'scheduler#my_reservations',      via: 'get'
  match '/unbound_requests',      to: 'scheduler#unbound_requests',     via: 'get'
  match '/make_unbound_requests', to: 'scheduler#make_unbound_requests',via: 'post'
  match '/make_reservation',      to: 'scheduler#make_reservation',     via: 'post'
  match '/confirm_reservations',  to: 'scheduler#confirm_reservations', via: 'post'
  post  'node_status/set_node_on'   => 'node_status#set_node_on'
  post  'node_status/set_node_off'  => 'node_status#set_node_off'
  post  'node_status/reset_node'    => 'node_status#reset_node'
  delete  'scheduler/cancel_reservation' => 'scheduler#cancel_reservation'

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
