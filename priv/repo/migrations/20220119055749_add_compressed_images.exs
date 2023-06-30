defmodule Jarm.Repo.Migrations.AddCompressedImages do
  use Ecto.Migration

  alias Jarm.Repo

  def up do
    alter table(:media) do
      add :path_to_compressed, :string
    end

    flush()

    import Ecto.Query, only: [from: 2]

    from("media", select: [:id, :mime_type, :path_to_original])
    |> Repo.all()
    |> Enum.map(fn m ->
      if m.mime_type |> String.starts_with?("image") do
        media_dir = Path.dirname(m.path_to_original)

        compressed_path =
          Path.join(
            media_dir,
            "compressed-#{Path.basename(m.path_to_original, Path.extname(m.path_to_original))}.webp"
          )

        System.cmd("magick", [
          "convert",
          "-strip",
          "-auto-orient",
          "-resize",
          "700",
          m.path_to_original,
          compressed_path
        ])

        from(me in "media", where: me.id == ^m.id)
        |> Repo.update_all(set: [path_to_compressed: compressed_path])
      else
        from(me in "media", where: me.id == ^m.id)
        |> Repo.update_all(set: [path_to_compressed: ""])
      end
    end)
  end

  def down do
    import Ecto.Query, only: [from: 2]

    from("media", select: [:path_to_compressed])
    |> Repo.all()
    |> Enum.map(fn m ->
      File.rm(m.path_to_compressed)
    end)

    alter table(:media) do
      remove :path_to_compressed
    end
  end
end
