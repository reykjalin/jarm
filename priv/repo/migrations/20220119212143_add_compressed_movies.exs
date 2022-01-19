defmodule InnerCircle.Repo.Migrations.AddCompressedMovies do
  use Ecto.Migration

  alias InnerCircle.Repo
  alias InnerCircle.Timeline.Media

  def up do
    import Ecto.Query, only: [from: 2]

    Repo.all(Media)
    |> Enum.map(fn m ->
      if m.mime_type |> String.starts_with?("video") do
        media_dir = Path.dirname(m.path_to_original)

        compressed_path =
          Path.join(
            media_dir,
            "compressed-#{Path.basename(m.path_to_original, Path.extname(m.path_to_original))}.mp4"
          )

        System.cmd("ffmpeg", [
          "-i",
          m.path_to_original,
          "-c:v",
          "libx264",
          "-maxrate",
          "2M",
          "-bufsize",
          "2M",
          "-crf",
          "23",
          "-movflags",
          "+faststart",
          compressed_path
        ])

        from(me in Media, where: me.id == ^m.id)
        |> Repo.update_all(set: [path_to_compressed: compressed_path])
      end
    end)
  end

  def down do
    import Ecto.Query, only: [from: 2]

    Repo.all(Media)
    |> Enum.map(fn m ->
      if m.mime_type |> String.starts_with?("video") do
        File.rm(m.path_to_compressed)

        from(me in Media, where: me.id == ^m.id)
        |> Repo.update_all(set: [path_to_compressed: ""])
      end
    end)
  end
end
