Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post 'process_image', to: 'images#process_image'
  get 'task_status', to: 'images#task_status'
end
