Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'static#index'

  get 'auth', to: 'auth#auth'
  get 'search', to: 'search#search'
  get 'record/:id', to: 'search#record', as: 'record'
  get 'ping', to: 'search#ping'
end
