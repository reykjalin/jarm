defmodule JarmWeb.CreatePostLive.Index do
  alias Jarm.Timeline.Media
  use JarmWeb, :live_view

  alias Jarm.Timeline
  alias Jarm.Timeline.Post

  import Canada, only: [can?: 2]

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    changeset = Post.changeset(%Post{}, %{})

    socket =
      allow_upload(
        socket,
        :media,
        # TODO: Accept a list of mime types instead.
        accept:
          ~w(image/png image/jpeg image/webp image/gif image/heic image/heif video/mp4 video/webm video/ogg video/quicktime),
        max_entries: String.to_integer(System.get_env("MAX_MEDIA_PER_POST", "5")),
        # Defautls to 1 GB.
        max_file_size: String.to_integer(System.get_env("MAX_FILE_SIZE", "1000000000")),
        chunk_timeout: 60_000
      )

    socket = assign(socket, :page_title, "New Post")

    {:ok,
     socket
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("New jarm"))
    |> assign(:post, %Post{})
    |> assign(:current_user, socket.assigns.current_user)
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Post.changeset(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, :new, post_params)
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media, ref)}
  end

  defp save_post(socket, :new, post_params) do
    current_user = socket.assigns.current_user

    socket =
      if current_user |> can?(create(Jarm.Timeline.Post)) do
        case Timeline.create_post(current_user, post_params) do
          {:ok, post} ->
            consume_uploaded_entries(socket, :media, fn meta, entry ->
              result =
                Timeline.create_media(
                  current_user,
                  post,
                  if(String.starts_with?(entry.client_type, "image"),
                    do: consume_image(meta, entry),
                    else: consume_video(meta, entry)
                  )
                )

              case result do
                {:ok, media} ->
                  Task.Supervisor.start_child(FireAndForget.TaskSupervisor, fn ->
                    Logger.log(:info, "Generating compressed and thumbnail versions of media…")

                    media_changeset =
                      if entry.client_type |> String.starts_with?("image"),
                        do: process_image(media),
                        else: process_video(media)

                    Logger.info("Compressed media and thumbnail generated.")
                    Logger.info(media_changeset)

                    Timeline.update_media(
                      media,
                      media_changeset
                    )
                  end)
              end

              result
            end)

            socket
            |> put_flash(:info, "Post created successfully")
            |> redirect(to: ~p"/#{socket.assigns.locale}")

          {:error, %Ecto.Changeset{} = changeset} ->
            assign(socket, changeset: changeset)
        end
      else
        socket
        |> put_flash(:error, "You're not allowed to create new posts")
        |> redirect(to: ~p"/#{socket.assigns.locale}")
      end

    {:noreply, socket}
  end

  defp consume_video(meta, entry) do
    media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")
    dest = Path.join(media_path, file_name(entry))

    # Create static folder if it doesn't exist, then copy file.
    if not File.exists?(media_path) do
      Logger.log(:info, "Media storage path did not exist, creating…")
      File.mkdir_p!(media_path)
      Logger.log(:info, "Media storage path created.")
    end

    # Move file to media path.
    File.rename!(meta.path, dest)

    # Generate a compressed version of the video if required.
    path_to_compressed =
      if entry.client_type != "video/mp4" do
        path = Path.join(media_path, "compressed-#{entry.uuid}.mp4") |> Path.absname()
        Ffmpeg.compress_video_and_convert_to_mp4(dest, path)
        path
      else
        nil
      end

    [width, height] =
      if entry.client_type |> String.starts_with?("image") do
        case ImageMagick.get_image_dimensions(dest) do
          {:ok, results} ->
            [results.width, results.height]

          _ ->
            Logger.error("Failed to detect image dimensions for image #{entry.uuid}")

            [0, 0]
        end
      else
        case Ffmpeg.get_video_dimensions(dest) do
          {:ok, results} ->
            [results.width, results.height]

          _ ->
            [0, 0]
        end
      end

    %{
      "path_to_original" => dest,
      "path_to_compressed" => path_to_compressed,
      "width" => width,
      "height" => height,
      "mime_type" => entry.client_type,
      "uuid" => entry.uuid
    }
  end

  defp consume_image(meta, entry) do
    media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")
    dest = Path.join(media_path, file_name(entry))

    # Create static folder if it doesn't exist, then copy file.
    if not File.exists?(media_path) do
      Logger.log(:info, "Media storage path did not exist, creating…")
      File.mkdir_p!(media_path)
      Logger.log(:info, "Media storage path created.")
    end

    # Move file to media path.
    File.rename!(meta.path, dest)

    [width, height] =
      if entry.client_type |> String.starts_with?("image") do
        case ImageMagick.get_image_dimensions(dest) do
          {:ok, results} ->
            [results.width, results.height]

          _ ->
            Logger.error("Failed to detect image dimensions for image #{entry.uuid}")

            [0, 0]
        end
      else
        case Ffmpeg.get_video_dimensions(dest) do
          {:ok, results} ->
            [results.width, results.height]

          _ ->
            [0, 0]
        end
      end

    %{
      "path_to_original" => dest,
      "width" => width,
      "height" => height,
      "mime_type" => entry.client_type,
      "uuid" => entry.uuid
    }
  end

  defp process_image(%Media{} = image) do
    Logger.info("Processing image #{image.id}.")

    media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")

    # Generate a compressed version of the image.
    compressed_path =
      if image.path_to_compressed == nil or image.path_to_compressed == "" or
           not File.exists?(image.path_to_compressed) do
        path =
          Path.join(media_path, "compressed-#{image.uuid}.webp") |> Path.absname()

        case ImageMagick.generate_compressed_image(image.path_to_original, path) do
          {:ok, _} ->
            Logger.info("Compressed image generated at #{path}")
            path

          {:error, _message, output} ->
            Logger.error("Failed to generate compressed image because: #{output}")
            nil
        end
      else
        image.path_to_compressed
      end

    thumbnail_path =
      if image.path_to_thumbnail == nil or image.path_to_thumbnail == "" or
           not File.exists?(image.path_to_thumbnail) do
        path =
          Path.join(media_path, "thumbnail-#{image.uuid}.webp") |> Path.absname()

        case ImageMagick.generate_thumbnail(image.path_to_original, path) do
          {:ok, _} ->
            Logger.info("Thumbnail for image generated at #{path}")
            path

          {:error, _} ->
            Logger.error("Failed to generate thumbnail for image.")
            nil
        end
      else
        image.path_to_thumbnail
      end

    # It makes the most sense to get the compressed dimensions here since
    # that's the one that will actually be displayed on the timeline.
    [width, height] =
      case ImageMagick.get_image_dimensions(compressed_path) do
        {:ok, results} ->
          [results.width, results.height]

        _ ->
          Logger.error("Failed to detect image dimensions for image #{image.id}")

          [0, 0]
      end

    Logger.info("Detected image dimensions (WxH): #{width}x#{height}.")

    lqip =
      case Sqip.generate_svg_data_uri(compressed_path) do
        {:ok, result} ->
          File.rm!(result.output_file)
          result.data_uri

        _ ->
          Logger.error("Failed to generate LQIP for image #{image.id}")

          # TODO: handle failure more gracefully.
          ""
      end

    Logger.info("Generated LQIP for image #{image.id}.")

    # TODO: Optimize with a Repo.all() query?
    %{
      path_to_compressed: compressed_path,
      path_to_thumbnail: thumbnail_path,
      width: width,
      height: height,
      lqip: lqip
    }
  end

  defp process_video(%Media{} = video) do
    media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")

    # Generate a compressed version of the video.
    compressed_path =
      if video.path_to_compressed == nil or video.path_to_compressed == "" or
           not File.exists?(video.path_to_compressed) do
        path =
          Path.join(media_path, "compressed-#{video.uuid}.webp") |> Path.absname()

        case Ffmpeg.compress_video_and_convert_to_mp4(video.path_to_original, path) do
          {:ok, _} ->
            Logger.info("Compressed video generated at #{path}")
            path

          {:error, _message, output} ->
            Logger.error("Failed to generate compressed video because: #{output}")
            nil
        end
      else
        video.path_to_compressed
      end

    thumbnail_path =
      if video.path_to_thumbnail == nil or video.path_to_thumbnail == "" or
           not File.exists?(video.path_to_thumbnail) do
        path =
          Path.join(media_path, "thumbnail-#{video.uuid}.webp") |> Path.absname()

        case Ffmpeg.generate_video_thumbnail(video.path_to_original, path) do
          {:ok, _} ->
            Logger.info("Thumbnail for video generated at #{path}")
            path

          {:error, _} ->
            Logger.error("Failed to generate thumbnail for video.")
            nil
        end
      else
        video.path_to_thumbnail
      end

    # It makes the most sense to get the compressed dimensions here since
    # that's the one that will actually be displayed on the timeline.
    [width, height] =
      case Ffmpeg.get_video_dimensions(compressed_path) do
        {:ok, results} ->
          [results.width, results.height]

        _ ->
          [0, 0]
      end

    Logger.info("Detected video dimensions (WxH): #{width}x#{height}.")

    lqip =
      case Sqip.generate_svg_data_uri(thumbnail_path) do
        {:ok, result} ->
          File.rm!(result.output_file)
          result.data_uri

        _ ->
          # TODO: handle failure more gracefully.
          ""
      end

    Logger.info("Generated LQIP for video #{video.id}.")

    # TODO: Optimize with a Repo.all() query?
    %{
      path_to_compressed: compressed_path,
      path_to_thumbnail: thumbnail_path,
      width: width,
      height: height,
      lqip: lqip
    }
  end

  defp file_name(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{ext}"
  end

  @impl true
  def handle_info({:post_created, _post}, socket) do
    # We don't broadcast creations.
    # TODO: broadcast creation to trigger a "show newer posts" link.
    {:noreply, socket}
  end
end
