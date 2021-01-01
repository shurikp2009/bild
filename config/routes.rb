Rails.application.routes.draw do
  


  resources :remote_files do
    member do
      get :download
      get :showf
    end
  end

  resources :folders
  resources :servers
  resources :files
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: 'remote_files#index'
end
