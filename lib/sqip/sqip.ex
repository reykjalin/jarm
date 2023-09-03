defmodule Sqip do
  def generate_svg_data_uri(path_to_image) do
    {output, exit_status} =
      System.cmd("sqip", [
        "--parseable-output",
        "--plugins",
        "primitive",
        "data-uri",
        "--primitive-rep",
        "50",
        "--input",
        path_to_image
      ])

    case exit_status do
      0 ->
        [output, data_uri] = String.split(output, "dataURIBase64:", parts: 2)

        [_, output_file] = String.split(output, "Stored at: ", parts: 2)
        [output_file, _] = String.split(output_file, "\n", parts: 2)

        {:ok, %{data_uri: String.trim(data_uri), output_file: String.trim(output_file)}}

      _ ->
        {:error, "Failed to generate low quality svg"}
    end
  end
end
