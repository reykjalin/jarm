defmodule InnerCircleWeb.CreatePostLive.Index do
  use InnerCircleWeb, :live_view

  alias InnerCircle.Timeline
  alias InnerCircle.Timeline.Post

  import Canada, only: [can?: 2]

  @impl true
  def mount(_params, session, socket) do
    socket = assign_current_user(socket, session)

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
      case current_user |> can?(create(InnerCircle.Timeline.Post)) do
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

                    Mogrify.open(dest)
                    |> Mogrify.resize("700")
                    |> Mogrify.custom("strip")
                    |> Mogrify.custom("auto-orient")
                    |> Mogrify.format("webp")
                    |> Mogrify.save(path: compressed_path)

                    System.cmd("magick", [
                      "convert",
                      "#{compressed_path}",
                      "-strip",
                      "-auto-orient",
                      "-resize",
                      "700",
                      thumbnail_path
                    ])

                    {:ok, hash} = Blurhash.downscale_and_encode(thumbnail_path, 4, 3)

                    # Convert HEIC and HEIF files to PNG.
                    if entry.client_type == "image/heic" or entry.client_type == "image/heif" do
                      png_path = Path.join(media_path, "#{entry.uuid}.png")

                      System.cmd("magick", [
                        "convert",
                        dest,
                        "-strip",
                        "-auto-orient",
                        png_path
                      ])

                      # We delete the original HEIC/HEIF file.
                      File.rm!(dest)

                      # TODO: Optimize with a Repo.all() query?
                      Timeline.create_media(current_user, post, %{
                        "path_to_original" => png_path,
                        "path_to_compressed" => compressed_path,
                        "path_to_thumbnail" => thumbnail_path,
                        "mime_type" => "image/png",
                        "uuid" => entry.uuid,
                        "blurhash" => hash
                      })
                    else
                      # TODO: Optimize with a Repo.all() query?
                      Timeline.create_media(current_user, post, %{
                        "path_to_original" => path_to_original,
                        "path_to_compressed" => compressed_path,
                        "path_to_thumbnail" => thumbnail_path,
                        "mime_type" => entry.client_type,
                        "uuid" => entry.uuid,
                        "blurhash" => hash
                      })
                    end
                  else
                    # Generate a compressed version of the image.
                    compressed_path =
                      Path.join(media_path, "compressed-#{entry.uuid}.mp4") |> Path.absname()

                    thumbnail_path =
                      Path.join(media_path, "thumbnail-#{entry.uuid}.webp") |> Path.absname()

                    System.cmd("ffmpeg", [
                      "-i",
                      dest,
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
                      compressed_path
                    ])

                    System.cmd("magick", [
                      "convert",
                      "#{compressed_path}[1]",
                      "-resize",
                      "700",
                      thumbnail_path
                    ])

                    {:ok, hash} = Blurhash.downscale_and_encode(thumbnail_path, 4, 3)

                    # TODO: Optimize with a Repo.all() query?
                    Timeline.create_media(current_user, post, %{
                      "path_to_original" => path_to_original,
                      "path_to_compressed" => compressed_path,
                      "path_to_thumbnail" => thumbnail_path,
                      "mime_type" => entry.client_type,
                      "uuid" => entry.uuid,
                      "blurhash" => hash
                    })
                  end
                end)
              end)

              socket
              |> put_flash(:info, "Post created successfully")
              |> push_redirect(to: Routes.post_index_path(socket, :index, socket.assigns.locale))

            {:error, %Ecto.Changeset{} = changeset} ->
              assign(socket, changeset: changeset)
          end

        false ->
          socket
          |> put_flash(:error, "You're not allowed to create new posts")
          |> push_redirect(to: Routes.post_index_path(socket, :index, socket.assigns.locale))
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
