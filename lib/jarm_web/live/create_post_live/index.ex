defmodule JarmWeb.CreatePostLive.Index do
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
      case current_user |> can?(create(Jarm.Timeline.Post)) do
        true ->
          case Timeline.create_post(current_user, post_params) do
            {:ok, post} ->
              # 1. Consume temp files
              # 2. Assign media to post
              consume_uploaded_entries(socket, :media, fn meta, entry ->
                Logger.info("Consuming upload at #{meta.path}:")
                Logger.info(entry)
                media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")
                dest = Path.join(media_path, file_name(entry))

                Logger.log(:info, "Saving consumed upload to #{dest}")

                # Create static folder if it doesn't exist, then copy file.
                if not File.exists?(media_path) do
                  Logger.log(:info, "Media storage path did not exist, creating…")
                  File.mkdir_p!(media_path)
                  Logger.log(:info, "Media storage path created.")
                end

                Logger.log(:info, "Saving original upload in media storage…")
                File.cp!(meta.path, dest)
                Logger.log(:info, "Original upload saved in media storage.")

                # After file has been copied, process it asynchronously.
                Task.Supervisor.start_child(FireAndForget.TaskSupervisor, fn ->
                  Logger.log(:info, "Generating compressed and thumbnail versions of media…")

                  media_changeset =
                    if entry.client_type |> String.starts_with?("image"),
                      do: process_image(entry),
                      else: process_video(entry)

                  Logger.info("Compressed media and thumbnail generated.")
                  Logger.info(media_changeset)

                  Timeline.create_media(
                    current_user,
                    post,
                    media_changeset
                  )
                end)
              end)

              socket
              |> put_flash(:info, "Post created successfully")
              |> redirect(to: ~p"/#{socket.assigns.locale}")

            {:error, %Ecto.Changeset{} = changeset} ->
              assign(socket, changeset: changeset)
          end

        false ->
          socket
          |> put_flash(:error, "You're not allowed to create new posts")
          |> redirect(to: ~p"/#{socket.assigns.locale}")
      end

    {:noreply, socket}
  end

  defp process_image(image_entry) do
    Logger.info("Processing image #{image_entry.uuid}.")

    media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")
    dest = Path.join(media_path, file_name(image_entry))
    path_to_original = Path.absname(dest)

    # Generate a compressed version of the image.
    compressed_path =
      Path.join(media_path, "compressed-#{image_entry.uuid}.webp") |> Path.absname()

    thumbnail_path =
      Path.join(media_path, "thumbnail-#{image_entry.uuid}.webp") |> Path.absname()

    case ImageMagick.generate_compressed_image(dest, compressed_path) do
      {:ok, _} ->
        Logger.info("Compressed image generated at #{compressed_path}")

      {:error, _message, output} ->
        Logger.error("Failed to generate compressed image because: #{output}")
    end

    case ImageMagick.generate_thumbnail(dest, thumbnail_path) do
      {:ok, _} ->
        Logger.info("Thumbnail for image generated at #{thumbnail_path}")

      {:error, _} ->
        Logger.error("Failed to generate thumbnail for image.")
    end

    # It makes the most sense to get the compressed dimensions here since
    # that's the one that will actually be displayed on the timeline.
    [width, height] =
      case ImageMagick.get_image_dimensions(compressed_path) do
        {:ok, results} ->
          [results.width, results.height]

        _ ->
          Logger.error("Failed to detect image dimensions for image #{image_entry.uuid}")

          [0, 0]
      end

    Logger.info("Detected image dimensions (WxH): #{width}x#{height}.")

    lqip =
      case Sqip.generate_svg_data_uri(compressed_path) do
        {:ok, result} ->
          File.rm!(result.output_file)
          result.data_uri

        _ ->
          Logger.error("Failed to generate LQIP for image #{image_entry.uuid}")

          # TODO: handle failure more gracefully.
          ""
      end

    Logger.info("Generated LQIP for image #{image_entry.uuid}.")

    # Convert HEIC and HEIF files to PNG.
    if image_entry.client_type == "image/heic" or image_entry.client_type == "image/heif" do
      Logger.info("Detected HEIC or HEIF format, converting to PNG…")
      png_path = Path.join(media_path, "#{image_entry.uuid}.png")

      ImageMagick.convert_without_resize(dest, png_path)
      Logger.info("PNG created at #{png_path}.")

      # We delete the original HEIC/HEIF file.
      File.rm!(dest)
      Logger.info("Original HEIC/HEIF image at #{dest} deleted.")

      # TODO: Optimize with a Repo.all() query?
      %{
        "path_to_original" => png_path,
        "path_to_compressed" => compressed_path,
        "path_to_thumbnail" => thumbnail_path,
        "width" => width,
        "height" => height,
        "mime_type" => "image/png",
        "uuid" => image_entry.uuid,
        "lqip" => lqip
      }
    else
      # TODO: Optimize with a Repo.all() query?
      %{
        "path_to_original" => path_to_original,
        "path_to_compressed" => compressed_path,
        "path_to_thumbnail" => thumbnail_path,
        "width" => width,
        "height" => height,
        "mime_type" => image_entry.client_type,
        "uuid" => image_entry.uuid,
        "lqip" => lqip
      }
    end
  end

  defp process_video(video_entry) do
    media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")
    dest = Path.join(media_path, file_name(video_entry))
    path_to_original = Path.absname(dest)

    # Generate a compressed version of the image.
    compressed_path =
      Path.join(media_path, "compressed-#{video_entry.uuid}.mp4") |> Path.absname()

    thumbnail_path =
      Path.join(media_path, "thumbnail-#{video_entry.uuid}.webp") |> Path.absname()

    Ffmpeg.compress_video_and_convert_to_mp4(dest, compressed_path)
    Logger.info("Compressed video generated at #{compressed_path}")

    Ffmpeg.generate_video_thumbnail(dest, thumbnail_path)
    Logger.info("Video thumbnail generated at #{thumbnail_path}")

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

    Logger.info("Generated LQIP for video #{video_entry.uuid}.")

    # TODO: Optimize with a Repo.all() query?
    %{
      "path_to_original" => path_to_original,
      "path_to_compressed" => compressed_path,
      "path_to_thumbnail" => thumbnail_path,
      "width" => width,
      "height" => height,
      "mime_type" => video_entry.client_type,
      "uuid" => video_entry.uuid,
      "lqip" => lqip
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
