Spree::Core::Engine.routes.draw do
  namespace :admin do
    resource :affiliate_settings
  end

  resources :affiliates, :only => [:show, :index, :new]

  match 'AF/:ref_id' => 'af#show', :module => :spree, :as => :af
end
