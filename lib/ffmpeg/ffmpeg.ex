defmodule Ffmpeg do
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
