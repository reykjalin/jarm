defmodule InnerCircle.MixProject do
  use Mix.Project

  def project do
    [
      app: :inner_circle,
      version: "0.7.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {InnerCircle.Application, []},
      extra_applications: [:logger, :runtime_tools, :bamboo, :bamboo_smtp]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bcrypt_elixir, "~> 2.3"},
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sqlite3, "~> 0.7.0"},
      {:phoenix_live_view, "~> 0.17.5"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_html, "~> 3.1"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:plug_cowboy, "~> 2.5"},
      {:bamboo, "~> 2.2.0"},
      {:bamboo_smtp, github: "fewlinesco/bamboo_smtp"},
      {:site_encrypt, "~> 0.4"},
      {:canada, github: "jarednorman/canada"},
      {:nebulex, "~> 2.3"},
      {:decorator, "~> 1.4"},
      {:mogrify, "~> 0.9.1"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.1", runtime: Mix.env() == :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": [
        "tailwind default --minify",
        "esbuild default --minify",
        "phx.digest"
      ]
    ]
  end
end
