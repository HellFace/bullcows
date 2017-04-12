Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  
  root to: "home#index"
  post "/", to: "home#set_name"
  get "/game", to: "game#index"
  mount ActionCable.server => "/cable"
  
end
