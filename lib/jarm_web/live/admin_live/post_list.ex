defmodule JarmWeb.AdminLive.PostList do
  use JarmWeb, :live_view

  alias Jarm.Timeline
  alias Jarm.Timeline.Post

  import Canada, only: [can?: 2]

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    posts = Timeline.list_all_posts()

    socket =
      assign(socket,
        posts: if(posts, do: posts, else: []),
        locale: locale
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, :edit, post_params)
  end

  defp save_post(socket, :edit, %{"id" => post_id, "locale" => new_locale}) do
    post = Timeline.get_post!(post_id)
    current_user = socket.assigns.current_user

    socket =
      case current_user |> can?(edit(post)) do
        true ->
          case Timeline.update_post(post, %{"locale" => new_locale}) do
            {:ok, _post} ->
              socket
              |> put_flash(:info, "Post updated successfully")

            {:error, %Ecto.Changeset{} = _changeset} ->
              socket
              |> put_flash(:error, "Failed to update post")
              |> push_redirect(to: ~p"/#{socket.assigns.locale}/admin/posts/list")
          end

        false ->
          socket
          |> put_flash(:error, "You're not allowed to modify this post")
          |> push_redirect(to: ~p"/#{socket.assigns.locale}/admin/posts/list")
      end

    {:noreply, socket}
  end
end
