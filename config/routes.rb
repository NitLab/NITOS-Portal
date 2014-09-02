Rails.application.routes.draw do
  resources :users
  resources :sessions, only: [:new, :create, :destroy]

  root  'static_pages#home'
  match '/signup',          to: 'users#new',                     via: 'get'
  match '/signin',          to: 'sessions#new',                  via: 'get'
  match '/signout',         to: 'sessions#destroy',              via: 'delete'
  match '/your_ssh_keys',   to: 'static_pages#your_ssh_keys',    via: 'get'
  match '/about',           to: 'static_pages#about',            via: 'get'
  match '/node_status',     to: 'static_pages#node_status',      via: 'get'
  match '/scheduler',       to: 'static_pages#scheduler',        via: 'get'
  match '/reservation',     to: 'static_pages#reservation',      via: 'post'
  post 'static_pages/set_node_on' => 'static_pages#set_node_on'
  post 'static_pages/set_node_off' => 'static_pages#set_node_off'
  post 'static_pages/reset_node' => 'static_pages#reset_node'
  post 'static_pages/reserve_node' => 'static_pages#reserve_node'

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
