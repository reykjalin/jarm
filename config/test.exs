use Mix.Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :jarm, Jarm.Repo,
  database: "./test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :jarm, JarmWeb.Endpoint,
  url: [host: "localhost"],
  http: [port: 4002],
  secret_key_base: "HIMQEPTD+LljCRQVpb3hcS2+bzTtZC3XxfGPmbcD4+qOXJsCclD5KQuIv+rvs3W8",
  live_view: [signing_salt: "TK/x3uS6"],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
