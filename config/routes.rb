Rails.application.routes.draw do
  root to: 'queuing_systems#edit'
  resource :queuing_system
end
