defmodule ImageMagick do
  def get_image_dimensions(path_to_image) do
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

  def generate_thumbnail(path_to_image, output_path) do
    if not File.exists?(path_to_image) do
      {:error, "Provided image does not exist"}
    else
      {_output, exit_status} =
        System.cmd("magick", [
          "convert",
          path_to_image,
          "-thumbnail",
          "100x100>",
          "-auto-orient",
          output_path
        ])

      case exit_status do
        0 ->
          {:ok, output_path}

        _ ->
          {:error, "Failed to generate thumbnail"}
      end
    end
  end

  def generate_compressed_image(path_to_image, output_path) do
    if not File.exists?(path_to_image) do
      {:error, "Provided image does not exist"}
    else
      {_output, exit_status} =
        System.cmd("magick", [
          "convert",
          path_to_image,
          "-strip",
          "-auto-orient",
          "-resize",
          "700",
          output_path
        ])

      case exit_status do
        0 ->
          {:ok, output_path}

        _ ->
          {:error, "Failed to compress image"}
      end
    end
  end

  def convert_without_resize(path_to_image, output_path) do
    if not File.exists?(path_to_image) do
      {:error, "Provided image does not exist"}
    else
      {_output, exit_status} =
        System.cmd("magick", [
          "convert",
          path_to_image,
          "-strip",
          "-auto-orient",
          output_path
        ])

      case exit_status do
        0 ->
          {:ok, output_path}

        _ ->
          {:error, "Failed to convert image"}
      end
    end
  end

  def layer_images_on_top_of_each_other(image_paths, output, size) do
    image_params =
      image_paths
      |> Enum.map(fn i ->
        Path.join([:code.priv_dir(:jarm), "avatar-generators", "cat", i])
      end)
      |> Enum.reduce([], fn i, acc ->
        acc ++ ["-page"] ++ ["+0+0"] ++ [i]
      end)

    IO.inspect(image_params ++ ["-layers", "flatten", "-resize", "#{size}x#{size}", output],
      label: "params"
    )

    {_output, exit_status} =
      System.cmd(
        "magick",
        image_params ++ ["-layers", "flatten", "-resize", "#{size}x#{size}", output]
      )

    case exit_status do
      0 ->
        :ok

      _ ->
        :error
    end
  end
end
