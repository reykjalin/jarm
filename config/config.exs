# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :inner_circle,
  ecto_repos: [InnerCircle.Repo]

# Configures the endpoint
config :inner_circle, InnerCircleWeb.Endpoint,
  render_errors: [view: InnerCircleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: InnerCircle.PubSub

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
