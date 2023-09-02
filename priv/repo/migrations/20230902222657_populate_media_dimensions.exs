defmodule Jarm.Repo.Migrations.PopulateMediaDimensions do
  use Ecto.Migration

  alias Jarm.Repo

  def up do
    import Ecto.Query, only: [from: 2]

    from("media", select: [:id, :mime_type, :path_to_original])
    |> Repo.all()
    |> Enum.map(fn m ->
      dimensions =
        if m.mime_type |> String.starts_with?("image") do
          get_image_dimensions(m.path_to_original)
        else
          get_video_dimensions(m.path_to_original)
        end

      [width, height] =
        case dimensions do
          {:ok, result} ->
            IO.inspect(result)
            [result.width, result.height]

          _ ->
            [0, 0]
        end

      from(me in "media", where: me.id == ^m.id)
      |> Repo.update_all(set: [width: width, height: height])
    end)
  end

  def down do
    # Nothing to do.
  end

  defp get_video_dimensions(path_to_video) do
    if not File.exists?(path_to_video) do
      {:error, "Provided video does not exist"}
    else
      {output, exit_status} =
        System.cmd("ffprobe", [
          "-v",
          "error",
          "-select_streams",
          "v",
          "-show_entries",
          "stream=width,height",
          "-of",
          "csv=p=0:s=x",
          path_to_video
        ])

      case exit_status do
        0 ->
          [width, height] = output |> String.trim() |> String.trim("x") |> String.split("x")

          {:ok,
           %{
             path: path_to_video,
             width: String.to_integer(width),
             height: String.to_integer(height)
           }}

        _ ->
          {:error, "Failed to get video dimensions"}
      end
    end
  end

  defp get_image_dimensions(path_to_image) do
    if not File.exists?(path_to_image) do
      {:error, "Provided image does not exist"}
    else
      {output, exit_status} =
        System.cmd("identify", [
          "-ping",
          "-format",
          "%w:%h",
          path_to_image
        ])

      if exit_status !== 0 do
        {:error, "Failed to identify image."}
      else
        [width, height] = output |> String.trim() |> String.split(":")

        {:ok,
         %{
           path: path_to_image,
           width: String.to_integer(width),
           height: String.to_integer(height)
         }}
      end
    end
  end
end
