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



    get 'commanders/public', to: 'commanders#public_list'
    get 'commanders', to: 'commanders#list'
    get 'commanders/roles', to: 'commanders#assignable'
    get 'commanders/:id', to: 'commanders#lookup'
    delete 'commanders/:id', to: 'commanders#revoke'
    post 'commanders', to: 'commanders#create'

    get 'sse/stream', to: 'sse#index'

    get 'fleet/members', to: 'fleet#members'
    get 'fleet/info', to: 'fleet#info'

    scope 'v2' do
      get 'announcements', to: 'announcements#list'
      post 'announcements', to: 'announcements#create'
      put 'announcements/:id', to: 'announcements#update'
      delete 'announcements/:id', to: 'announcements#destroy'

      get 'bans/:id', to: 'bans#show'
      get 'bans', to: 'bans#list'
      post 'bans', to: 'bans#create'

      get 'fleets', to: 'fleets/configure#index'
      post 'fleets', to: 'fleets/configure#register'
      delete 'fleets', to: 'fleets/configure#close_all'
      scope 'fleets' do
        get 'history', to: 'fleets/historic#history'
        get ':fleet_id/waitlist', to: 'fleets/waitlist#fleet_waitlist'
        get ':fleet_id/comp', to: 'fleets/comp#comp'
        post ':fleet_id/boss', to: 'fleets/settings#update_boss'
        post ':fleet_id/visibility', to: 'fleets/settings#update_visibility'
        post ':fleet_id/size', to: 'fleets/settings#update_size'
        post ':fleet_id/actions/invite-all', to: 'fleets/actions#invite_all'
        delete ':fleet_id', to: 'fleets/actions#delete_fleet'
        get ':fleet_id', to: 'fleets/settings#get_fleet'
      end
    end

    get 'waitlist', to: 'waitlist/list#index'
    delete 'waitlist', to: 'waitlist/actions#empty_waitlist'
    scope 'waitlist' do
      post 'xup', to: 'waitlist/xup#xup'
      post 'remove_fit', to: 'waitlist/actions#remove'
      post 'message', to: 'waitlist/message#send_message'
      post 'reject', to: 'waitlist/message#reject'
      post 'approve', to: 'waitlist/message#approve'
      post 'invite', to: 'waitlist/invite#invite'
    end

    get 'implants', to: 'implants#list_implants'



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

    get 'history/xup', to: 'history/xup#index'

    post 'open_window', to: 'window#create'

    get 'skills', to: 'skills#list_skills'

    get 'search', to: 'search#query'
    post 'search', to: 'search#esi_search'

    get 'badges', to: 'badges#index'
    post 'badges/:id/members', to: 'badges#assign'
    delete 'badges/:id/members/:character_id', to: 'badges#revoke'
    get 'badges/:badge_id/members', to: 'badges#get_badge_members'

    get 'stats', to: 'statistics#statistics'

    get 'reports', to: 'reports#index'

    get 'categories', to: 'categories#index'
  end
  # Auth routes

end
