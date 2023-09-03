defmodule Jarm.Repo.Migrations.AddMediaBlurhash do
  use Ecto.Migration

  alias Jarm.Repo

  def up do
    alter table(:media) do
      add(:blurhash, :string)
    end

    # ========
    # The rest is commented out due to the Blurhash library being removed.
    # Uncomment if you need it.
    # ========

    # flush()

    # import Ecto.Query, only: [from: 2]

    # from("media", select: [:id, :path_to_thumbnail])
    # |> Repo.all()
    # |> Enum.map(fn m ->
    #   # Generate blurhash
    #   {:ok, hash} = Blurhash.downscale_and_encode(m.path_to_thumbnail, 4, 3)

    #   # Add blurhash to db.
    #   from(me in "media", where: me.id == ^m.id)
    #   |> Repo.update_all(set: [blurhash: hash])
    # end)
  end

  def down do
    alter table(:media) do
      remove(:blurhash)
    end
  end
end
