defmodule InnerCircle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the cache
      InnerCircle.Cache,
      # Start the Ecto repository
      InnerCircle.Repo,
      # Start the Telemetry supervisor
      InnerCircleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: InnerCircle.PubSub},
      # Start the Endpoint (http/https)
      {SiteEncrypt.Phoenix, InnerCircleWeb.Endpoint},
      # Start a worker by calling: InnerCircle.Worker.start_link(arg)
      # {InnerCircle.Worker, arg}
      # Start the supervision tree under the OTP Application.
      {Task.Supervisor, name: FireAndForget.TaskSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: InnerCircle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    InnerCircleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
