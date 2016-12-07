Rails.application.routes.draw do
  root to: 'mass_service_systems#index'
  resource :mass_service_systems
end
