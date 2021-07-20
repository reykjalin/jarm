defmodule InnerCircle.Cache do
  use Nebulex.Cache,
    otp_app: :inner_circle,
    adapter: Nebulex.Adapters.Local
end
