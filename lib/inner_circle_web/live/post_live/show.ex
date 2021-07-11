defmodule InnerCircleWeb.PostLive.Show do
  use InnerCircleWeb, :live_view

  alias InnerCircle.Timeline

  import Canada, only: [can?: 2]

  @impl true
  def mount(_params, session, socket) do
    socket = assign_current_user(socket, session)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    post = Timeline.get_post!(id)
    current_user = socket.assigns.current_user

    socket =
      case current_user |> can?(read(post)) do
        true ->
          socket
          |> assign(:page_title, page_title(socket.assigns.live_action))
          |> assign(:post, Timeline.get_post!(id))

        false ->
          socket
          |> put_flash(:error, "You're not allowed to view this post")
          |> push_redirect(
            to: Routes.post_index_path(socket, :index),
            replace: true
          )
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    current_user = socket.assigns.current_user
    post = Timeline.get_post!(id)

    socket =
      case current_user |> can?(delete(post)) do
        true ->
          {:ok, _} = Timeline.delete_post(post)

          socket
          |> put_flash(:info, "Post deleted")
          |> push_redirect(
            to: Routes.post_index_path(socket, :index),
            replace: true
          )

        false ->
          socket
          |> put_flash(:error, "You're not allowed to delete this post")
          |> push_patch(to: Routes.post_show_path(socket, :show, id))
      end

    {
      :noreply,
      socket
    }
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
