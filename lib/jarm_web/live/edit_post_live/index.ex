defmodule JarmWeb.EditPostLive.Index do
  use JarmWeb, :live_view

  alias Jarm.Timeline
  alias Jarm.Timeline.Post

  import Canada, only: [can?: 2]

  @impl true
  def mount(params, session, socket) do
    socket = assign_current_user(socket, session)

    post = Timeline.get_post!(params["id"])
    socket = assign(socket, :post, post)

    changeset = Post.changeset(post, %{})

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

    socket = assign(socket, :page_title, gettext("Edit jarm"))

    {:ok,
     socket
     |> assign(:changeset, changeset)}
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
    save_post(socket, :edit, post_params)
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
              |> push_redirect(to: Routes.post_index_path(socket, :index))

            {:error, %Ecto.Changeset{} = changeset} ->
              assign(socket, :changeset, changeset)
          end

        false ->
          socket
          |> put_flash(:error, "You're not allowed to modify this post")
          |> push_redirect(to: Routes.post_index_path(socket, :index))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:post_created, _post}, socket) do
    # We don't broadcast edits.
    # TODO: broadcast creation to trigger a "show newer posts" link.
    {:noreply, socket}
  end
end
