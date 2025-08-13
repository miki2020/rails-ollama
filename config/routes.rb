Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Registration routes
  resource :registration, only: [:new, :create]
  
  get "up" => "rails/health#show", as: :rails_health_check
  get '/debug/ollama_health', to: 'application#ollama_health'
  get '/debug/generate_affirmations', to: 'affirmations#debug_generate_affirmations'

  resources :affirmations do
    member do
      get :toggle_favorite
    end

    collection do
      post :generate_today
      delete :clear_today
      delete :clear_day
    end
  end

  root 'affirmations#index'
end
