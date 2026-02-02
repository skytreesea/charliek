Rails.application.routes.draw do
  # Root route must be defined first
  root to: "home#index"
  
  devise_for :users, controllers: { registrations: "users/registrations" }
  resource :nickname, only: [:edit, :update], controller: :nicknames
  get "coins", to: "coins#index", as: :coins

  get "posts", to: "posts#index"
  
  # new, create는 slug 라우팅보다 먼저 정의 (우선순위 보장)
  resources :posts, only: [:new, :create]
  
  # Slug 기반 라우팅 (SEO 친화적)
  get "posts/:slug", to: "posts#show", as: :post
  get "posts/:slug/edit", to: "posts#edit", as: :edit_post
  patch "posts/:slug", to: "posts#update"
  put "posts/:slug", to: "posts#update"
  delete "posts/:slug", to: "posts#destroy"
  post "posts/:slug/like", to: "posts#like", as: :like_post
  delete "posts/:slug/unlike", to: "posts#unlike", as: :unlike_post
  delete "posts/:slug/admin_destroy", to: "posts#admin_destroy", as: :admin_destroy_post
  
  # Comments는 slug 기반 post에 연결
  post "posts/:slug/comments", to: "comments#create", as: :post_comments
  delete "posts/:slug/comments/:id", to: "comments#destroy", as: :post_comment
  
  # 기존 ID 기반 라우팅 (301 리다이렉트용 호환성 유지)
  get "posts/:id", to: "posts#show_by_id", constraints: { id: /\d+/ }
  get "home/index", to: "home#index", as: "home_index"
  get "about", to: "about#index", as: "about"
  get "post/index"
  resources :guestbooks, only: [:index, :create, :destroy]
  
  # Static pages
  get "privacy", to: "pages#privacy", as: "privacy_policy"
  
  # Backtest routes
  get "backtests", to: "backtests#index", as: "backtests"
  post "backtests/calculate", to: "backtests#calculate", as: "backtests_calculate"
  get "backtests/share/:id", to: "backtests#share", as: "backtest_share"
  
  # MyMuse routes
  get "mymuse", to: "mymuse#index", as: "mymuse"
  post "mymuse/create", to: "mymuse#create", as: "mymuse_create"
  
  # Compositions routes
  resources :compositions, only: [:index, :create]
  
  # 기사생성기 (development 전용)
  # production 환경에서는 컨트롤러에서 접근 차단
  resources :articles
  
  namespace :admin do
    resources :users, only: [:index] do
      collection do
        patch :update_roles
        patch :update_role
        patch :update_roles_batch
      end
    end
    resources :design, only: [:index] do
      collection do
        patch :update
      end
    end
    get "home", to: "home#index", as: "home_index"
    patch "home/update", to: "home#update", as: "home_update"
    resources :uploads, only: [:index, :create, :destroy]
  end
  
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  
  # Edge 브라우저 호환성을 위한 favicon.ico 서빙
  get "favicon.ico", to: "favicon#show"
  
  # Google AdSense ads.txt 서빙 (안전장치: public/ads.txt가 서빙되지 않는 경우 대비)
  get "ads.txt", to: "ads_txt#show"
  
  # SEO: Sitemap
  get "sitemap.xml", to: "sitemap#index", format: "xml"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
