Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  scope '/api' do
    post 'auth/wiki', to: 'auth#set_wiki_passwd'
    get 'auth/whoami', to: 'auth#whoami'
    get 'auth/logout', to: 'auth#logout'
    get 'auth/login_url', to: 'auth#login_url'
    post 'auth/cb', to: 'auth#callback'

    get 'v2/announcements', to: 'announcements#list'
    post 'v2/announcements', to: 'announcements#create'
    put 'v2/announcements/:id', to: 'announcements#update'
    delete 'v2/announcements/:id', to: 'announcements#destroy'

    get 'commanders/public', to: 'commanders#public_list'

    get 'sse/stream', to: 'sse#index'

    get 'fleet/members', to: 'fleet#members'

    get 'waitlist', to: 'waitlist#index'

    post 'fit-check', to: 'fit_check#fit_check'

    get 'module/preload', to: 'modules#preload'
    get 'module/info', to: 'modules#module_info'

    get 'fittings', to: 'fittings#index'

    get 'pilot/alts', to: 'pilots#alts'
    get 'pilot/info', to: 'pilots#info'

    get 'history/fleet', to: 'history/activity#fleet_history'
    get 'history/skills', to: 'history/skills#skills'

    get 'notes', to: 'notes#index'
    post 'notes/add', to: 'notes#create'

    get 'v2/bans/:id', to: 'bans#show'

    get 'history/xup', to: 'history/xup#index'

    post 'open_window', to: 'window#create'

    get 'skills', to: 'skills#list_skills'

    get 'search', to: 'search#query'

    get 'badges', to: 'badges#index'
    post 'badges/:id/members', to: 'badges#assign'
    delete 'badges/:id/members/:character_id', to: 'badges#revoke'
  end
  # Auth routes


end
