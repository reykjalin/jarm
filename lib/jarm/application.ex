defmodule Jarm.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the cache
      Jarm.Cache,
      # Start the Ecto repository
      Jarm.Repo,
      # Start the Telemetry supervisor
      JarmWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Jarm.PubSub},
      # Start the Endpoint (http/https)
      JarmWeb.Endpoint,
      # Start a worker by calling: Jarm.Worker.start_link(arg)
      # {Jarm.Worker, arg}
      # Start the supervision tree under the OTP Application.
      {Task.Supervisor, name: FireAndForget.TaskSupervisor},
      # Scheduler for notifications.
      Jarm.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Jarm.Supervisor, applications: [:set_locale]]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    JarmWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
