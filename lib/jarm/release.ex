defmodule Jarm.Release do
  @app :jarm

  alias Jarm.Accounts
  alias Jarm.Administrator

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  def send_invitation(email) do
    url_func = &"/en/users/register/#{&1}"
    Accounts.deliver_user_invitation(email, url_func)
  end

  def grant_administrator_privileges_to(email) do
    Accounts.get_user_by_email(email)
    |> Administrator.grant_administrator_privileges_to()
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
