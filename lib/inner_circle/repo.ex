defmodule InnerCircle.Repo do
  use Ecto.Repo,
    otp_app: :inner_circle,
    adapter: Ecto.Adapters.SQLite3
end
