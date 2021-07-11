defmodule InnerCircleWeb.PostLive.Show do
  use InnerCircleWeb, :live_view

  alias InnerCircle.Timeline

  @impl true
  def mount(_params, session, socket) do
    socket = assign_current_user(socket, session)
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {
      :noreply,
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:post, Timeline.get_post!(id))
    }
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Timeline.get_post!(id)
    {:ok, _} = Timeline.delete_post(post)

    socket = put_flash(socket, :info, "Post deleted")

    {
      :noreply,
      push_redirect(
        socket,
        to: Routes.post_index_path(socket, :index),
        replace: true
      )
    }
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"
end
