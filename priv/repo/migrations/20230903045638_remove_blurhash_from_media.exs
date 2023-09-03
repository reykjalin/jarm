defmodule Jarm.Repo.Migrations.RemoveBlurhashFromMedia do
  use Ecto.Migration

  alias Jarm.Repo

  def up do
    alter table(:media) do
      remove(:blurhash)
    end
  end

  def down do
    # Copied from 20230328050706_add_media_blurhash.exs.
    alter table(:media) do
      add(:blurhash, :string)
    end

    flush()

    import Ecto.Query, only: [from: 2]
    import Mogrify

    from("media", select: [:id, :path_to_thumbnail])
    |> Repo.all()
    |> Enum.map(fn m ->
      # Generate blurhash
      {:ok, hash} = Blurhash.downscale_and_encode(m.path_to_thumbnail, 4, 3)

      # Add blurhash to db.
      from(me in "media", where: me.id == ^m.id)
      |> Repo.update_all(set: [blurhash: hash])
    end)
  end
end
