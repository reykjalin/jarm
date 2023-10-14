defmodule JarmWeb.AdminLive.MediaList do
  use JarmWeb, :live_view

  require Logger

  alias Jarm.Administrator

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    media = Administrator.get_all_media()

    socket =
      assign(socket,
        media: if(media, do: Enum.reverse(media), else: []),
        compressing_for: [],
        thumbnails_generating_for: [],
        lqip_generating_for: [],
        locale: locale
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("compress", %{"ID" => media_id}, socket) do
    send(self(), {:compress_original, String.to_integer(media_id)})

    socket =
      assign(
        socket,
        compressing_for:
          socket.assigns.compressing_for |> List.insert_at(-1, String.to_integer(media_id))
      )

    {:noreply, socket}
  end

  def handle_event("thumbnail", %{"ID" => media_id}, socket) do
    send(self(), {:generate_thumbnail, String.to_integer(media_id)})

    socket =
      assign(
        socket,
        thumbnails_generating_for:
          socket.assigns.thumbnails_generating_for
          |> List.insert_at(-1, String.to_integer(media_id))
      )

    {:noreply, socket}
  end

  def handle_event("lqip", %{"ID" => media_id}, socket) do
    send(self(), {:generate_lqip, String.to_integer(media_id)})

    socket =
      assign(
        socket,
        lqip_generating_for:
          socket.assigns.lqip_generating_for
          |> List.insert_at(-1, String.to_integer(media_id))
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:compress_original, id}, socket) do
    IO.inspect(id, label: "(compress) Media id")
    media = Jarm.Timeline.get_media_by_id(id)

    media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")

    path_to_compressed =
      if String.starts_with?(media.mime_type, "image") do
        Path.join(media_path, "compressed-#{media.uuid}.webp") |> Path.absname()
      else
        Path.join(media_path, "compressed-#{media.uuid}.mp4") |> Path.absname()
      end

    if String.starts_with?(media.mime_type, "image") do
      result = ImageMagick.generate_compressed_image(media.path_to_original, path_to_compressed)
      IO.inspect(result, label: "convert result")
    else
      Ffmpeg.compress_video_and_convert_to_mp4(media.path_to_original, path_to_compressed, true)
    end

    Jarm.Timeline.update_media(media, %{path_to_compressed: path_to_compressed})

    socket =
      assign(
        socket,
        media: Administrator.get_all_media() |> Enum.reverse(),
        compressing_for: socket.assigns.compressing_for |> List.delete(id)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:generate_thumbnail, id}, socket) do
    IO.inspect(id, label: "(thumbnail) Media id")
    media = Jarm.Timeline.get_media_by_id(id)

    media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")

    thumbnail_path =
      Path.join(media_path, "thumbnail-#{media.uuid}.webp") |> Path.absname()

    src =
      if media.path_to_compressed != nil and media.path_to_compressed != "" and
           File.exists?(media.path_to_compressed) do
        media.path_to_compressed
      else
        media.path_to_original
      end

    if String.starts_with?(media.mime_type, "image") do
      ImageMagick.generate_thumbnail(src, thumbnail_path)
    else
      Ffmpeg.generate_video_thumbnail(src, thumbnail_path)
    end

    Jarm.Timeline.update_media(media, %{path_to_thumbnail: thumbnail_path})

    socket =
      assign(
        socket,
        media: Administrator.get_all_media() |> Enum.reverse(),
        thumbnails_generating_for: socket.assigns.thumbnails_generating_for |> List.delete(id)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:generate_lqip, id}, socket) do
    IO.inspect(id, label: "(lqip) Media id")
    media = Jarm.Timeline.get_media_by_id(id)

    lqip_source_image =
      if String.starts_with?(media.mime_type, "image") do
        if media.path_to_compressed != nil and media.path_to_compressed != "" and
             File.exists?(media.path_to_compressed) do
          media.path_to_compressed
        else
          media.path_to_original
        end
      else
        if media.path_to_thumbnail != nil and media.path_to_thumbnail != "" and
             File.exists?(media.path_to_thumbnail) do
          media.path_to_thumbnail
        else
          # Generate thumbnail.
          media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")

          thumbnail_path =
            Path.join(media_path, "thumbnail-#{media.uuid}.webp") |> Path.absname()

          src =
            if media.path_to_compressed != nil and media.path_to_compressed != "" and
                 File.exists?(media.path_to_compressed) do
              media.path_to_compressed
            else
              media.path_to_original
            end

          Ffmpeg.generate_video_thumbnail(src, thumbnail_path)
          Jarm.Timeline.update_media(media, %{path_to_thumbnail: thumbnail_path})

          thumbnail_path
        end
      end

    lqip =
      case Sqip.generate_svg_data_uri(lqip_source_image) do
        {:ok, result} ->
          File.rm!(result.output_file)
          result.data_uri

        _ ->
          Logger.error("Failed to generate LQIP for image #{media.id}")

          # TODO: handle failure more gracefully.
          ""
      end

    Jarm.Timeline.update_media(media, %{lqip: lqip})

    socket =
      assign(
        socket,
        media: Administrator.get_all_media() |> Enum.reverse(),
        lqip_generating_for: socket.assigns.lqip_generating_for |> List.delete(id)
      )

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl pb-5"><%= gettext("Media") %></h1>

    <.card>
      <details
        :for={m <- @media}
        class="py-5 border-b border-solid last:border-none"
        open={
          Enum.member?(@compressing_for, m.id) or Enum.member?(@thumbnails_generating_for, m.id) or
            Enum.member?(@lqip_generating_for, m.id)
        }
      >
        <summary><%= m.id %></summary>
        <p class="my-2">ID: <%= m.id %></p>

        <p class="my-2">
          Post ID: <.link href={~p"/#{@locale}/posts/#{m.post_id}"}><%= m.post_id %></.link>
        </p>

        <div class="my-2">
          <p class="my-1">
            Path to original:
            <span :if={not File.exists?(m.path_to_original)}>
              <.icon name="hero-x-mark" class="text-red-500" />
            </span>
            <span :if={File.exists?(m.path_to_original)}>
              <.icon name="hero-check" class="text-green-500" />
              <.link href={~p"/media/#{m.uuid}"}>[direct link]</.link>
            </span>
          </p>
          <pre class="overflow-auto border border-solid p-2"><%= m.path_to_original %></pre>
        </div>

        <div class="my-2">
          <form action={~p"/#{@locale}/admin/media/list"} phx-submit="compress">
            <.input type="hidden" name="ID" value={m.id} />
            <p class="my-1">
              Path to compressed:
              <span :if={
                m.path_to_compressed == nil or m.path_to_compressed == "" or
                  not File.exists?(m.path_to_compressed)
              }>
                <.icon name="hero-x-mark" class="text-red-500" />
              </span>
              <span :if={
                m.path_to_compressed != nil and m.path_to_compressed != "" and
                  File.exists?(m.path_to_compressed)
              }>
                <.icon name="hero-check" class="text-green-500" />
                <.link href={~p"/compressed-media/#{m.uuid}"}>[direct link]</.link>
              </span>

              <.button
                type="submit"
                class="bg-green-500 hover:bg-green-300 disabled:bg-red-500 disabled:hover:bg-red-300"
                disabled={Enum.member?(@compressing_for, m.id)}
              >
                <.icon
                  name="hero-arrow-path"
                  class={if Enum.member?(@compressing_for, m.id), do: "animate-spin"}
                />
              </.button>
            </p>
          </form>
          <pre class="overflow-auto border border-solid p-2"><%= if m.path_to_compressed == nil or m.path_to_compressed == "", do: "-", else: m.path_to_compressed %></pre>
        </div>

        <div :if={String.starts_with?(m.mime_type, "image")} class="my-2">
          <form action={~p"/#{@locale}/admin/media/list"} phx-submit="thumbnail">
            <.input type="hidden" name="ID" value={m.id} />
            <p class="my-1">
              <%= gettext("Path to thumbnail") %>:
              <span :if={
                m.path_to_thumbnail == nil or m.path_to_thumbnail == "" or
                  not File.exists?(m.path_to_thumbnail)
              }>
                <.icon name="hero-x-mark" class="text-red-500" />
              </span>
              <span :if={
                m.path_to_thumbnail != nil and m.path_to_thumbnail != "" and
                  File.exists?(m.path_to_thumbnail)
              }>
                <.icon name="hero-check" class="text-green-500" />
                <.link href={~p"/thumbnail/#{m.uuid}"}>[direct link]</.link>
              </span>

              <.button
                class="bg-green-500 hover:bg-green-300 disabled:bg-red-500 disabled:hover:bg-red-300"
                disabled={Enum.member?(@thumbnails_generating_for, m.id)}
              >
                <.icon
                  name="hero-arrow-path"
                  class={if Enum.member?(@thumbnails_generating_for, m.id), do: "animate-spin"}
                />
              </.button>
            </p>
          </form>
          <pre class="overflow-auto border border-solid p-2"><%= if m.path_to_thumbnail == nil or m.path_to_thumbnail == "", do: "-", else: m.path_to_thumbnail %></pre>
        </div>

        <div class="my-2">
          <form action={~p"/#{@locale}/admin/media/list"} phx-submit="lqip">
            <.input type="hidden" name="ID" value={m.id} />
            <p>
              <%= gettext("LQIP") %>:
              <.icon :if={m.lqip == nil or m.lqip == ""} name="hero-x-mark" class="text-red-500" />
              <.icon :if={m.lqip != nil and m.lqip != ""} name="hero-check" class="text-green-500" />

              <.button
                class="bg-green-500 hover:bg-green-300 disabled:bg-red-500 disabled:hover:bg-red-300"
                disabled={Enum.member?(@lqip_generating_for, m.id)}
              >
                <.icon
                  name="hero-arrow-path"
                  class={if Enum.member?(@lqip_generating_for, m.id), do: "animate-spin"}
                />
              </.button>
            </p>
          </form>
        </div>
      </details>
    </.card>
    """
  end
end
