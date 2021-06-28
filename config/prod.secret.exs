# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_path = System.get_env("DATABASE_PATH") || "./prod.sqlite3"

smtp_username =
  case System.get_env("SMTP_USERNAME") do
    nil ->
      raise """
      environment variable SMTP_USERNAME is missing.
      Please set the SMTP_USERNAME before starting Inner Circle.
      """

    "" ->
      raise """
      environment variable SMTP_USERNAME is missing.
      Please set the SMTP_USERNAME before starting Inner Circle.
      """

    value ->
      value
  end

smtp_password =
  case System.get_env("SMTP_PASSWORD") do
    nil ->
      raise """
      environment variable SMTP_PASSWORD is missing.
      Please set the SMTP_PASSWORD before starting Inner Circle.
      """

    "" ->
      raise """
      environment variable SMTP_PASSWORD is missing.
      Please set the SMTP_PASSWORD before starting Inner Circle.
      """

    value ->
      value
  end

smtp_server =
  case System.get_env("SMTP_SERVER") do
    nil ->
      raise """
      environment variable SMTP_SERVER is missing.
      Please set the SMTP_SERVER before starting Inner Circle.
      """

    "" ->
      raise """
      environment variable SMTP_SERVER is missing.
      Please set the SMTP_SERVER before starting Inner Circle.
      """

    value ->
      value
  end

smtp_port =
  case System.get_env("SMTP_PORT") do
    nil ->
      raise """
      environment variable SMTP_PORT is missing.
      Please set the SMTP_PORT before starting Inner Circle.
      """

    "" ->
      raise """
      environment variable SMTP_PORT is missing.
      Please set the SMTP_PORT before starting Inner Circle.
      """

    value ->
      value
  end

smtp_retries = System.get_env("SMTP_RETRIES") || "0"

config :inner_circle, InnerCircle.Repo, database: database_path
# ssl: true,

secret_key_base =
  case System.get_env("SECRET_KEY_BASE") do
    nil ->
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

    "" ->
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

    value ->
      value
  end

config :inner_circle, InnerCircleWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "80"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

## Email support
config :inner_circle, InnerCircle.Mailer,
  adapter: Bamboo.SMTPAdapter,
  server: smtp_server,
  username: smtp_username,
  password: smtp_password,
  ssl: true,
  tls: :if_available,
  auth: :always,
  port: String.to_integer(smtp_port),
  retries: String.to_integer(smtp_retries),
  no_mx_lookups: true

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
config :inner_circle, InnerCircleWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
