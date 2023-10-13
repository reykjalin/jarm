defmodule JarmWeb.MediaController do
  use JarmWeb, :controller

  alias Jarm.Timeline
  alias Jarm.Timeline.Media

  def show(conn, %{"id" => id}) do
    case Timeline.get_media(id) do
      nil ->
        conn
        |> put_status(404)
        |> text("File not found")

      %Media{} = media ->
        # We need to do some special handling.
        if media.mime_type |> String.starts_with?("video") do
          show_video(conn, media)
        else
          show_image(conn, media)
        end
    end
  end

  def show_compressed(conn, %{"id" => id}) do
    case Timeline.get_media(id) do
      nil ->
        conn
        |> put_status(404)
        |> text("File not found")

      %Media{} = media ->
        IO.inspect(media, label: "found media:")
        # We need to do some special handling.
        if media.mime_type |> String.starts_with?("video") do
          show_video(conn, media, true)
        else
          show_image(conn, media, true)
        end
    end
  end

  def show_thumbnail(conn, %{"id" => id}) do
    case Timeline.get_media(id) do
      nil ->
        conn
        |> put_status(404)
        |> text("File not found")

      %Media{} = media ->
        conn
        |> Plug.Conn.put_resp_header("content-type", "image/webp")
        |> Plug.Conn.put_resp_header("cache-control", "private,max-age=31536000,immutable")
        |> Plug.Conn.send_file(200, media.path_to_thumbnail)
    end
  end

  defp show_image(conn, media, compressed \\ false) do
    media_path = if compressed, do: media.path_to_compressed, else: media.path_to_original
    mime_type = if compressed, do: "image/webp", else: media.mime_type

    IO.inspect(media, label: "found media:")

    if media_path != nil and media_path != "" and File.exists?(media_path) do
      conn
      |> Plug.Conn.put_resp_content_type(mime_type)
      |> Plug.Conn.put_resp_header("cache-control", "private,max-age=31536000,immutable")
      |> Plug.Conn.send_file(200, media_path)
    else
      conn
      |> put_status(404)
      |> text("File not found")
    end
  end

  defp show_video(conn, media, compressed \\ false) do
    headers = conn.req_headers
    media_path = if compressed, do: media.path_to_compressed, else: media.path_to_original
    mime_type = if compressed, do: "video/mp4", else: media.mime_type
    %{size: file_size} = File.stat!(media_path)

    [start_range, end_range] = get_video_ranges(headers, file_size)

    # TODO: send error response when ranges are unsupported.
    #  SEE: https://datatracker.ietf.org/doc/html/rfc7233#section-4.4
    conn
    |> Plug.Conn.put_resp_header(
      "content-range",
      "bytes #{start_range}-#{end_range}/#{file_size}"
    )
    |> Plug.Conn.put_resp_header("cache-control", "private,max-age=31536000, immutable")
    |> Plug.Conn.put_resp_header("content-type", mime_type)
    |> Plug.Conn.send_file(
      206,
      media_path,
      start_range,
      1 + end_range - start_range
    )
  end

  defp get_video_ranges(headers, file_size) do
    case List.keyfind(headers, "range", 0) do
      {"range", "bytes=" <> ranges} ->
        [start_range | rest] = String.split(ranges, "-", parts: 2)

        end_range =
          case rest do
            [] -> file_size - 1
            [""] -> file_size - 1
            [rest] -> String.split(rest, ",", parts: 2) |> hd |> String.to_integer()
          end

        [String.to_integer(start_range), end_range]

      nil ->
        [0, file_size - 1]
    end
  end
end
