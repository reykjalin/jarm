defmodule Jarm.Repo do
  use Ecto.Repo,
    otp_app: :jarm,
    adapter: Ecto.Adapters.SQLite3
end
