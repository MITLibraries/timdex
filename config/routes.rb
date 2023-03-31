Rails.application.routes.draw do
  mount Flipflop::Engine => "/flipflop"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  post "/graphql", to: "graphql#execute"
  devise_for :users
  
  root to: 'static#index'

  namespace :api do
    namespace :v1 do
      get 'auth', to: 'auth#auth'
    end
  end
end
