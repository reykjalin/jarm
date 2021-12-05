defmodule InnerCircleWeb.CreatePostLive.Index do
  use InnerCircleWeb, :live_view

  alias InnerCircle.Timeline.Post

  @impl true
  def mount(_params, session, socket) do
    socket = assign_current_user(socket, session)

    socket =
      assign(socket,
        changeset: Post.changeset(%Post{}, %{})
      )

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

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, Timeline.get_post!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{})
    |> assign(:current_user, socket.assigns.current_user)
  end

  defp apply_action(socket, :index, _params) do
    socket
    # |> assign(:page_title, "Timeline")
    # |> assign(:post, nil)
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Post.changeset(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end
end
