Rails.application.routes.draw do
  # Organization registration routes
  namespace :organizations do
    get 'register', to: 'registrations#new', as: 'register'
    post 'register', to: 'registrations#create'
  end
  
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    passwords: 'users/passwords'
  }
  root "welcome#index"
  
  # Organizations routes for multi-tenancy
  resources :organizations, only: [:show, :edit, :update]
  
  # Project management routes
  resources :projects do
    resources :artifacts, except: [:index] do
      member do
        get :download
      end
    end
    
    resources :invitations do
      member do
        post :resend
      end
    end
  end
  
  # Standalone invitation acceptance (no authentication required)
  get 'invitations/:token/accept', to: 'invitations#accept', as: 'accept_invitation'
  post 'invitations/:token/accept', to: 'invitations#accept'
  
  # Dashboard for signed-in users
  get 'dashboard', to: 'projects#index'
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
