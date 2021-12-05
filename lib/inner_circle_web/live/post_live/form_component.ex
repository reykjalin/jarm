defmodule InnerCircleWeb.PostLive.FormComponent do
  use InnerCircleWeb, :live_component

  alias InnerCircle.Timeline
  alias InnerCircle.Timeline.Post

  import Canada, only: [can?: 2]

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Timeline.change_post(post)

    socket =
      allow_upload(
        socket,
        :media,
        # TODO: Accept a list of mime types instead.
        accept:
          ~w(image/png image/jpeg image/webp image/gif video/mp4 video/webm video/ogg video/quicktime),
        max_entries: String.to_integer(System.get_env("MAX_MEDIA_PER_POST", "5")),
        # Defautls to 1 GB.
        max_file_size: String.to_integer(System.get_env("MAX_FILE_SIZE", "1000000000"))
      )

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{})
    |> assign(:current_user, socket.assigns.current_user)
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Timeline.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :media, ref)}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    post = socket.assigns.post
    current_user = socket.assigns.current_user

    socket =
      case current_user |> can?(edit(post)) do
        true ->
          case Timeline.update_post(socket.assigns.post, post_params) do
            {:ok, _post} ->
              socket
              |> put_flash(:info, "Post updated successfully")
              |> push_redirect(to: socket.assigns.return_to)

            {:error, %Ecto.Changeset{} = changeset} ->
              assign(socket, :changeset, changeset)
          end

        false ->
          socket
          |> put_flash(:error, "You're not allowed to modify this post")
          |> push_redirect(to: socket.assigns.return_to)
      end

    {:noreply, socket}
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

                # TODO: Optimize with a Repo.all() query?
                Timeline.create_media(current_user, post, %{
                  "path_to_original" => path_to_original,
                  "mime_type" => entry.client_type,
                  "uuid" => entry.uuid
                })
              end)

              socket
              |> put_flash(:info, "Post created successfully")
              |> push_redirect(to: socket.assigns.return_to)

            {:error, %Ecto.Changeset{} = changeset} ->
              assign(socket, changeset: changeset)
          end

        false ->
          socket
          |> put_flash(:error, "You're not allowed to create new posts")
          |> push_redirect(to: socket.assigns.return_to)
      end

    {:noreply, socket}
  end

  defp file_name(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{ext}"
  end
end
