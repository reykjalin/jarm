defmodule InnerCircle.Repo.Migrations.AddCompressedImages do
  use Ecto.Migration

  alias InnerCircle.Repo
  alias InnerCircle.Timeline.Media

  def up do
    alter table(:media) do
      add :path_to_compressed, :string
    end

    flush()

    import Ecto.Query, only: [from: 2]

    Repo.all(Media)
    |> Enum.map(fn m ->
      if m.mime_type |> String.starts_with?("image") do
        media_dir = Path.dirname(m.path_to_original)

        compressed_path =
          Path.join(
            media_dir,
            "compressed-#{Path.basename(m.path_to_original, Path.extname(m.path_to_original))}.jpeg"
          )

        System.cmd("magick", [
          "convert",
          "-sampling-factor",
          "4:2:0",
          "-strip",
          "-quality",
          "40",
          "-interlace",
          "JPEG",
          "-colorspace",
          "sRGB",
          "-auto-orient",
          m.path_to_original,
          compressed_path
        ])

        from(me in Media, where: me.id == ^m.id)
        |> Repo.update_all(set: [path_to_compressed: compressed_path])
      else
        from(me in Media, where: me.id == ^m.id)
        |> Repo.update_all(set: [path_to_compressed: ""])
      end
    end)
  end

  def down do
    Repo.all(Media)
    |> Enum.map(fn m ->
      File.rm(m.path_to_compressed)
    end)

    alter table(:media) do
      remove :path_to_compressed
    end
  end
end
