defmodule InnerCircleWeb.Router do
  use InnerCircleWeb, :router

  import InnerCircleWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {InnerCircleWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :static do
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_user
    plug :require_authenticated_user

    plug Plug.Static,
      at: "/media",
      from: System.get_env("MEDIA_FILE_STORAGE", "priv/static/media"),
      gzip: true
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Other scopes may use custom stacks.
  # scope "/api", InnerCircleWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: InnerCircleWeb.Telemetry
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end
  end

  ## Authentication routes

  scope "/", InnerCircleWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register/:token", UserRegistrationController, :new
    post "/users/register/:token", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/media", InnerCircleWeb do
    # see https://binarynoggin.com/blog/saving-the-day-with-secure-static-files-in-phoenix/
    # wayback machine: http://web.archive.org/web/20210401122722/https://binarynoggin.com/blog/saving-the-day-with-secure-static-files-in-phoenix/
    pipe_through [:static]
    get "/*path", StaticFileNotFoundController, :index
  end

  scope "/", InnerCircleWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
    get "/users/invite", UserInvitationController, :new
    post "/users/invite", UserInvitationController, :create

    # Posts
    live "/", PostLive.Index, :index
    live "/posts/new", PostLive.Index, :new

    live "/posts/:id", PostLive.Show, :show
    # TODO: enable when role based authentication is in place.
    live "/posts/:id/edit", PostLive.Index, :edit
    live "/posts/:id/show/edit", PostLive.Show, :edit
  end

  scope "/", InnerCircleWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
  end
end
