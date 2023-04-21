Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post 'process_image', to: 'images#process_image'
  get 'task_status', to: 'images#task_status'
  get 'testing_it', to: 'images#testing_it'
  post 'designs', to: 'images#create_designs'
  get 'designs', to: 'images#get_designs'
  post 'test_designs', to: 'images#test_designs'
end
