defmodule Jarm.Repo.Migrations.PopulateUserConfiguration do
  use Ecto.Migration

  import Ecto.Changeset

  alias Jarm.Repo

  def up do
    import Ecto.Query, only: [from: 2]

    empty_configs =
      from("users", select: [:id, :email, :display_name])
      |> Repo.all()
      |> Enum.map(fn u ->
        %{
          user_id: u.id,
          inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
          updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        }
      end)

    Repo.insert_all("user_configuration", empty_configs)
  end

  def down do
    # Nothing to do.
  end
end
