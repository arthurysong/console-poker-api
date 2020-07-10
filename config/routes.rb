Rails.application.routes.draw do
  resources :rounds
  resources :games
  resources :messages
  resources :chatboxes
  resources :rooms do
    resources :games, only: [:index, :create]
  end

  resources :users
  post '/auth/:site', to: 'authentication#authenticate'
  # get '/auth/google/callback', to: 'authentication#authenticate'
  # get /auth/:

  post '/rooms/:id/authenticate', to: 'rooms#authenticate'

  post '/users/:id/make_move', to: 'users#make_move'
  post '/users/:id/add_chips', to: 'users#add_chips' # do i need to have id in route?
  get '/users/:id/get_chips', to: 'users#get_chips'

  post '/games/:id/start', to: 'games#start'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  post '/authenticate', to: 'authentication#authenticate'
  get '/test', to: 'authentication#test'
  get '/set_login', to: 'authentication#set_login'

  #payments
  get '/secret/:amount', to: 'payments#secret'
  get '/stripe_state', to: 'payments#state';

  mount ActionCable.server => '/cable'
end
