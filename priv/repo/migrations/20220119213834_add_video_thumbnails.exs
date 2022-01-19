defmodule InnerCircle.Repo.Migrations.AddVideoThumbnails do
  use Ecto.Migration

  alias InnerCircle.Repo

  def up do
    alter table(:media) do
      add :path_to_thumbnail, :string
    end

    flush()

    import Ecto.Query, only: [from: 2]

    from("media", select: [:id, :mime_type, :path_to_original, :path_to_compressed])
    |> Repo.all()
    |> Enum.map(fn m ->
      media_dir = Path.dirname(m.path_to_original)

      thumbnail_path =
        Path.join(
          media_dir,
          "thumbnail-#{Path.basename(m.path_to_original, Path.extname(m.path_to_original))}.webp"
        )

      System.cmd("magick", [
        "convert",
        "#{m.path_to_compressed}[1]",
        "-resize",
        "700",
        thumbnail_path
      ])

      from(me in "media", where: me.id == ^m.id)
      |> Repo.update_all(set: [path_to_thumbnail: thumbnail_path])
    end)
  end

  def down do
    import Ecto.Query, only: [from: 2]

    from("media", select: [:path_to_thumbnail, :mime_type])
    |> Repo.all()
    |> Enum.map(fn m ->
      if m.mime_type |> String.starts_with?("video") do
        File.rm(m.path_to_thumbnail)
      end
    end)

    alter table(:media) do
      remove :path_to_thumbnail
    end
  end
end
