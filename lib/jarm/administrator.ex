defmodule Jarm.Administrator do
  @moduledoc """
  The Administration context.
  """

  import Ecto.Query, warn: false
  alias Jarm.Repo

  alias Jarm.Accounts.{User}

  def grant_administrator_privileges_to(user) do
    changeset =
      user
      |> User.grant_administrator_privileges_changeset(%{is_admin: true})

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

end
