defmodule Jarm.Cache do
  use Nebulex.Cache,
    otp_app: :jarm,
    adapter: Nebulex.Adapters.Local
end
