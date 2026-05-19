Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "/up", to: proc { [200, { "Content-Type" => "application/json" }, [{ ok: true }.to_json]] }

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  namespace :api do
    get  "/league_starters", to: "recommendations#league_starters"
    post "/diagnose_build",  to: "recommendations#diagnose_build"

    resources :patch_documents, only: [:index, :show, :create] do
      post :parse, on: :member
      get :summary, on: :member
    end
  end
end
