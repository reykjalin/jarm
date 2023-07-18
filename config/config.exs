# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :jarm,
  ecto_repos: [Jarm.Repo]

# Configures the endpoint
config :jarm, JarmWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: JarmWeb.ErrorHTML, json: JarmWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Jarm.PubSub

# Configure locales
config :jarm, JarmWeb.Gettext, default_locale: "en", locales: ~w(en is fil)

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
    --config=tailwind.config.js
    --input=css/app.css
    --output=../priv/static/assets/app.css
  ),
    cd: Path.expand(~c"../assets", __DIR__)
  ]

# Set the UUID type to binary to fix the default representation after updating
# to ecto_sqlite3 0.7.0.
config :ecto_sqlite3, uuid_type: :binary, binary_id_type: :binary

config :jarm, env: config_env()

config :jarm, Jarm.Scheduler,
  jobs: [
    new_post_and_comment_notifications: [
      schedule: "@daily",
      task: {Jarm.Notifications, :send_notifications, []}
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
