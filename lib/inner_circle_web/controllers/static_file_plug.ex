defmodule InnerCircleWeb.StaticFilePlug do
  @behaviour Plug

  @impl true
  def init(_opts) do
    []
  end

  @impl true
  def call(conn, _opts) do
    dynamic_opts =
      Plug.Static.init(
        at: "/media",
        from: System.get_env("MEDIA_FILE_STORAGE", "priv/static/media"),
        gzip: true
      )

    Plug.Static.call(conn, dynamic_opts)
  end
end
