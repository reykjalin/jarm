defmodule JarmWeb.CreatePostLive.Index do
  use JarmWeb, :live_view

  alias Jarm.Timeline
  alias Jarm.Timeline.Post

  import Canada, only: [can?: 2]

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
                media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")
                dest = Path.join(media_path, file_name(entry))
                path_to_original = Path.absname(dest)

                # Create static folder if it doesn't exist, then copy file.
                if not File.exists?(media_path),
                  do: File.mkdir_p!(media_path)

                File.cp!(meta.path, dest)

                # After file has been copied, process it asynchronously.
                Task.Supervisor.start_child(FireAndForget.TaskSupervisor, fn ->
                  if entry.client_type |> String.starts_with?("image") do
                    # Generate a compressed version of the image.
                    compressed_path =
                      Path.join(media_path, "compressed-#{entry.uuid}.webp") |> Path.absname()

                    thumbnail_path =
                      Path.join(media_path, "thumbnail-#{entry.uuid}.webp") |> Path.absname()

                    ImageMagick.generate_compressed_image(dest, compressed_path)
                    ImageMagick.generate_thumbnail(dest, thumbnail_path)

                    # It makes the most sense to get the compressed dimensions here since
                    # that's the one that will actually be displayed on the timeline.
                    [width, height] =
                      case ImageMagick.get_image_dimensions(compressed_path) do
                        {:ok, results} ->
                          [results.width, results.height]

                        _ ->
                          [0, 0]
                      end

                    lqip =
                      case Sqip.generate_svg_data_uri(compressed_path) do
                        {:ok, result} ->
                          result.data_uri

                        _ ->
                          # TODO: handle failure more gracefully.
                          ""
                      end

                    # Convert HEIC and HEIF files to PNG.
                    if entry.client_type == "image/heic" or entry.client_type == "image/heif" do
                      png_path = Path.join(media_path, "#{entry.uuid}.png")

                      ImageMagick.convert_without_resize(dest, png_path)

                      # We delete the original HEIC/HEIF file.
                      File.rm!(dest)

                      # TODO: Optimize with a Repo.all() query?
                      Timeline.create_media(current_user, post, %{
                        "path_to_original" => png_path,
                        "path_to_compressed" => compressed_path,
                        "path_to_thumbnail" => thumbnail_path,
                        "width" => width,
                        "height" => height,
                        "mime_type" => "image/png",
                        "uuid" => entry.uuid,
                        "lqip" => lqip
                      })
                    else
                      # TODO: Optimize with a Repo.all() query?
                      Timeline.create_media(current_user, post, %{
                        "path_to_original" => path_to_original,
                        "path_to_compressed" => compressed_path,
                        "path_to_thumbnail" => thumbnail_path,
                        "width" => width,
                        "height" => height,
                        "mime_type" => entry.client_type,
                        "uuid" => entry.uuid,
                        "lqip" => lqip
                      })
                    end
                  else
                    # Generate a compressed version of the image.
                    compressed_path =
                      Path.join(media_path, "compressed-#{entry.uuid}.mp4") |> Path.absname()

                    thumbnail_path =
                      Path.join(media_path, "thumbnail-#{entry.uuid}.webp") |> Path.absname()

                    Ffmpeg.compress_video_and_convert_to_mp4(dest, compressed_path)
                    Ffmpeg.generate_video_thumbnail(dest, thumbnail_path)

                    # It makes the most sense to get the compressed dimensions here since
                    # that's the one that will actually be displayed on the timeline.
                    [width, height] =
                      case Ffmpeg.get_video_dimensions(compressed_path) do
                        {:ok, results} ->
                          [results.width, results.height]

                        _ ->
                          [0, 0]
                      end

                    lqip =
                      case Sqip.generate_svg_data_uri(compressed_path) do
                        {:ok, result} ->
                          result.data_uri

                        _ ->
                          # TODO: handle failure more gracefully.
                          ""
                      end

                    # TODO: Optimize with a Repo.all() query?
                    Timeline.create_media(current_user, post, %{
                      "path_to_original" => path_to_original,
                      "path_to_compressed" => compressed_path,
                      "path_to_thumbnail" => thumbnail_path,
                      "width" => width,
                      "height" => height,
                      "mime_type" => entry.client_type,
                      "uuid" => entry.uuid,
                      "lqip" => lqip
                    })
                  end
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
