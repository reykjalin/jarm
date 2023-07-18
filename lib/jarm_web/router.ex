defmodule JarmWeb.Router do
  use JarmWeb, :router

  import JarmWeb.UserAuth
  import JarmWeb.Locale

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {JarmWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :set_locale do
    plug(SetLocale,
      gettext: JarmWeb.Gettext,
      default_locale: "en",
      cookie_key: "jarm_locale"
    )

    plug(:set_locale_cookie, gettext: JarmWeb.Gettext)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :media do
    # Accept supported media types
    plug :accepts, [
      "video/mp4",
      "video/quicktime",
      "video/webm",
      "video/ogg",
      "image/jpeg",
      "image/png",
      "image/gif",
      "image/webp"
    ]

    plug :fetch_session
    plug :put_secure_browser_headers
    plug :fetch_current_user
    # Require login that just returns 401 Unauthorized
    plug :require_authenticated_media_request
  end

  # Other scopes may use custom stacks.
  # scope "/api", JarmWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Application.compile_env(:jarm, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: JarmWeb.Telemetry
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end
  end

  # Required for localization, apparently never called as per set_locale plug documentation.
  scope "/", JarmWeb do
    pipe_through [:browser, :set_locale, :require_authenticated_user]
    live "/", PostLive.Index, :dummy
    live "/posts/:id", PostLive.Show, :dummy
  end

  ## Authentication routes

  scope "/:locale", JarmWeb do
    pipe_through :set_locale
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{JarmWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register/:token", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :new
    end

    post "/users/log_in", UserSessionController, :create

    # get "/users/register/:token", UserRegistrationController, :new
    # post "/users/register/:token", UserRegistrationController, :create
    # get "/users/log_in", UserSessionController, :new
    # post "/users/log_in", UserSessionController, :create
    # get "/users/reset_password", UserResetPasswordController, :new
    # post "/users/reset_password", UserResetPasswordController, :create
    # get "/users/reset_password/:token", UserResetPasswordController, :edit
    # put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  ## App routes.

  scope "/:locale", JarmWeb do
    pipe_through [:browser, :set_locale, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{JarmWeb.UserAuth, :ensure_authenticated}] do
      # Posts
      live "/", PostLive.Index, :index
      live "/posts/new", CreatePostLive.Index, :new

      live "/posts/:id", PostLive.Show, :show
      live "/posts/:id/edit", EditPostLive.Index, :index
      live "/posts/:id/add_translation", EditPostLive.AddTranslation, :index

      # Media list page.
      live "/media", MediaLive.Index, :index

      # Account routes
      live "/users/settings", UserSettingsLive, :edit
      live "/users/invite", UserInvitationsLive, :new
    end

    # TODO: make this a live view?
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email

    # get "/users/settings", UserSettingsController, :edit
    # put "/users/settings", UserSettingsController, :update
    # get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
    # get "/users/invite", UserInvitationController, :new
    # post "/users/invite", UserInvitationController, :create
  end

  ## Static media routes.

  scope "/", JarmWeb do
    pipe_through :media

    # Media
    get "/media/:id", MediaController, :show
    get "/compressed-media/:id", MediaController, :show_compressed
    get "/thumbnail/:id", MediaController, :show_thumbnail
  end

  ## Admin rotues.

  scope "/:locale", JarmWeb do
    pipe_through [:browser, :set_locale, :require_admin_user]

    live_session :require_admin_user,
      on_mount: [{JarmWeb.UserAuth, :ensure_authenticated_admin}] do
      live "/admin/users/list", AdminLive.UserList, :index
      live "/admin/invitations/list", AdminLive.InvitationsList, :index
      live "/admin/posts/list", AdminLive.PostList, :index
    end
  end

  scope "/:locale", JarmWeb do
    pipe_through [:browser, :set_locale]

    delete "/users/log_out", UserSessionController, :delete
  end
end
