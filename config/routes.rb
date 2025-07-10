Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  
  resources :affirmations do
    member do
      patch :toggle_favorite
    end
    
    collection do
      post :generate_today
      delete :clear_today
    end
  end
  
  root 'affirmations#index'
end
