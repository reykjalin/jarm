# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :inner_circle,
  ecto_repos: [InnerCircle.Repo]

# Configures the endpoint
config :inner_circle, InnerCircleWeb.Endpoint,
  render_errors: [view: InnerCircleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: InnerCircle.PubSub

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Set the UUID type to binary to fix the default representation after updating
# to ecto_sqlite3 0.7.0.
config :ecto_sqlite3, uuid_type: :binary, binary_id_type: :binary

config :inner_circle, env: config_env()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
