Rails.application.routes.draw do
  
  get 'main/index'
  get 'gallery/index'
  get 'photo/index'

  resources :remote_files do
    member do
      get :download
    end
  end

  resources :folders
  resources :servers
  resources :files
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root to: 'folders#index'
end
