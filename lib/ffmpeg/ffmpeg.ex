defmodule Ffmpeg do
  def get_video_dimensions(path_to_video) do
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

          {:ok, %{path: path_to_video, width: width, height: height}}

        _ ->
          {:error, "Failed to get video dimensions"}
      end
    end
  end

  def compress_video_and_convert_to_mp4(path_to_video, output_path) do
    if not File.exists?(path_to_video) do
      {:error, "Provided video does not exist"}
    else
      {_output, exit_status} =
        System.cmd("ffmpeg", [
          "-i",
          path_to_video,
          "-c:v",
          "libx264",
          "-maxrate",
          "2M",
          "-bufsize",
          "2M",
          "-crf",
          "23",
          "-pix_fmt",
          "yuv420p",
          "-movflags",
          "+faststart",
          output_path
        ])

      case exit_status do
        0 ->
          {:ok, output_path}

        _ ->
          {:error, "Failed to compress video"}
      end
    end
  end

  def generate_video_thumbnail(path_to_video, output_path) do
    if not File.exists?(path_to_video) do
      {:error, "Provided video does not exist"}
    else
      # "Thumbnail" here doesn't actually use thumbnail size becasue it's really used as
      # the poster for the video while it's loading.
      {_output, exit_status} =
        System.cmd("magick", [
          "convert",
          "#{path_to_video}[1]",
          "-resize",
          "700",
          output_path
        ])

      case exit_status do
        0 ->
          {:ok, output_path}

        _ ->
          {:error, "Failed to compress video"}
      end
    end
  end
end
