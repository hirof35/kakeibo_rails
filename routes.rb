Rails.application.routes.draw do
  resources :records
  root "records#index"
  
  post "update_budget", to: "records#update_budget"
  # これを追加
  post "update_category_budget", to: "records#update_category_budget"
end
