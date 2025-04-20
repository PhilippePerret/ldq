defmodule LdQWeb.Router do
  use LdQWeb, :router

  import LdQWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LdQWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LdQWeb do
    pipe_through :browser

    get "/testmail", ChantierController, :test_mail
    
    # L'accueil
    get "/", PageLocaleController, :home
  end

  
  scope "/", LdQWeb do
    pipe_through [:browser, :require_authenticated_user, :required_admin]

    get "/admin-section", AdminController, :home
    post "/page_locales/new", PageLocaleController, :new
    get "/page_locales/:id/update-content", PageLocaleController, :update_content
    
    resources "/pages", PageController
    resources "/page_locales", PageLocaleController
  end

  # Nouvel affichage des pages (depuis la base de donnée)
  scope "/pg", LdQWeb do
    pipe_through :browser
    
    get "/:slug", PageLocaleController, :display
  end
  
  scope "/form", LdQWeb do
    pipe_through [:browser, :require_authenticated_user]
    
    get "/:form", FormController, :edit
    post "/:form", FormController, :create
  end

  scope "/livres", LdQWeb do
    pipe_through :browser
  
    get "/", ChantierController, :voie_sans_issue
    get "/soumettre", ChantierController, :voie_sans_issue
  	get "/choisir", ChantierController, :voie_sans_issue
  	get "/classement", ChantierController, :voie_sans_issue
	  get "/new", ChantierController, :voie_sans_issue
 
  end

  scope "/comite", LdQWeb do
    pipe_through :browser

    get "/", ComiteController, :portail
    get "/actu", ComiteController, :actu
    get "/regles_objectives", ComiteController, :regles_objectives
    get "/conditions_admission", ChantierController, :voie_sans_issue
    get "/postuler", ChantierController, :voie_sans_issue
  end


  # Other scopes may use custom stacks.
  # scope "/api", LdQWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ldq, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LdQWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LdQWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{LdQWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", LdQWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{LdQWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", LdQWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{LdQWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
