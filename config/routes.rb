BulSearch::Application.routes.draw do
  root "easy#home"

  #catalog
  blacklight_for :catalog
  post 'catalog/sms' => 'catalog#sms'
  Blacklight::Marc.add_routes(self)
  get 'catalog/:id/ourl' => 'catalog#ourl_service', as: :catalog_service_ourl
  devise_for :users, :controllers => {omniauth_callbacks: 'omniauth_callbacks'},
      :skip => [:sessions]

  # bookplate_list
  get 'catalog/bookplate/:code' => 'catalog#bookplate'

  #easySearch
  get 'about' => 'easy#about', as: :easy_about
  get "easy/search"
  get 'easy/' => 'easy#home', as: :easyS
  get 'easy/search'

  #libweb
  get 'libweb/' => 'libweb#search', as: :lib_web

  # Browse (aka Virtual Shelf)
  get 'browse/' => 'browse#random', as: :browse_random
  get 'browse/about' => 'browse#about', as: :browse_about
  get 'browse/:id' => 'browse#from_item', as: :browse_item

  # Course Reserves
  get 'reserves/search' => 'reserves#search', as: :reserves_search
  get 'reserves/:classid/:classnumber' => 'reserves#show', as: :reserves_show
  get 'reserves/' => 'reserves#search'

  # Stub controller to test the Availability Service
  get 'availability/test_auth' => 'availability#test_auth'
  get 'availability/fake/:id' => 'availability#fake_one'
  post 'availability/fake/' => 'availability#fake_many'
  get 'availability/forward/:id' => 'availability#forward_one'
  post 'availability/forward/' => 'availability#forward_many'

  # Patron controller
  post 'patron/checkouts' => 'patron#checkouts'

  # API controller
  get 'api/items/ids' => 'api#items_ids', as: :api_items_ids
  get 'api/items/by_location' => 'api#items_by_location'
  get 'api/items/nearby' => 'api#items_nearby'
  get 'api/items/shelf_item/:id' => 'api#shelf_item'
  get 'api/items/shelf_items' => 'api#shelf_items'

  # Museum integration
  get 'museum/thumbnail/:id' => 'museum#thumbnail', as: :museum_thumbnail

  # Stats
  get 'stats/eds' => 'stats#eds'
  get 'stats/server' => 'stats#server'
  get 'stats/solr-master' => 'stats#solr_master'

  # Collection Ecosystem Project
  get 'dashboard/new' => 'dashboard#new', as: :dashboard_new
  get 'dashboard/copy/:id' => 'dashboard#copy', as: :dashboard_copy
  get 'dashboard/:id/edit' => 'dashboard#edit', as: :dashboard_edit
  post 'dashboard/:id/edit' => 'dashboard#save', as: :dashboard_save
  post 'dashboard/:id/delete' => 'dashboard#delete', as: :dashboard_delete

  get 'dashboard/:id/download/acq_vs_chk' => 'dashboard#download_acquired_vs_checkedout', as: :dashboard_download_acq_vs_chk
  get 'dashboard/:id/details' => 'dashboard#details', as: :dashboard_details
  get 'dashboard/:id' => 'dashboard#show', as: :dashboard_show
  get 'dashboard/' => 'dashboard#index', as: :dashboard_index

  # Hay Flags Project
  get 'pullslips/:id/print' => 'pullslips#print', as: :pullslips_print
  get 'pullslips/:id' => 'pullslips#show', as: :pullslips_show
  get 'pullslips' => 'pullslips#index', as: :pullslips_index
  get 'hay/flags', to: redirect('/pullslips')

  # Best Bets editor
  get 'bestbets/:id/edit' => 'best_bets#edit', as: :best_bets_edit
  post 'bestbets/:id/save' => 'best_bets#save', as: :best_bets_save
  post 'bestbets/:id/delete' => 'best_bets#delete', as: :best_bets_delete
  get 'bestbets/' => 'best_bets#index', as: :best_bets_index

  # Legacy
  get 'Search/Results' => "legacy#search_results"
  get 'Search' => "legacy#search"

  # This is a duplicate route from the one that gem blacklight_advanced_search
  # adds on its own (https://github.com/projectblacklight/blacklight_advanced_search/blob/release-5.x/config/routes.rb)
  # We add it here so that it precedes the catch all route and it is recognized.
  # Newer versions of the gem handle this better.
  get 'advanced' => 'advanced#index'

  # Catch-all route
  if Rails.env.production?
    get '*path' => "easy#not_found"
  end
end
