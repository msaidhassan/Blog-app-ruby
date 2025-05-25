require 'sidekiq/web'

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Sidekiq Web UI with custom admin constraint
  mount Sidekiq::Web => '/sidekiq', constraints: AdminConstraint.new

  namespace :api do
    # Health check
    get 'health/check', to: 'health#check'

    # Authentication routes
    post '/login', to: 'authentication#login'
    post '/register', to: 'authentication#register'
    post '/logout', to: 'authentication#logout'
    patch '/update_image', to: 'authentication#update_image'
    get '/users/:id/image', to: 'authentication#serve_image'

    # Posts routes with nested comments
    resources :posts do
      resources :comments, only: [:index, :create, :update, :destroy]
    end

    # Tags routes
    resources :tags
  end
end
