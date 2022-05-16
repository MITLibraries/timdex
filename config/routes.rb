Rails.application.routes.draw do
  mount Flipflop::Engine => "/flipflop"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  post "/graphql", to: "graphql#execute"
  devise_for :users
  
  root to: 'static#index'

  namespace :api do
    namespace :v1 do
      get 'auth', to: 'auth#auth'
      get 'search', to: 'search#search'
      get 'info', to: 'search#info'
      get 'record/:id', to: 'search#record', as: 'record', constraints: { id: /[^\/]+/ }
      get 'ping', to: 'search#ping'
    end

    if ENV.fetch('V2', false)
      namespace :v2 do
        get 'auth', to: 'auth#auth'
        get 'search', to: 'search#search'
        get 'info', to: 'search#info'
        get 'record/:id', to: 'search#record', as: 'record', constraints: { id: /[^\/]+/ }
        get 'ping', to: 'search#ping'
      end
    end
  end
end
