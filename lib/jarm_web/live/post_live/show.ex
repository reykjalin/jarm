defmodule JarmWeb.PostLive.Show do
  use JarmWeb, :live_view

  alias Jarm.Timeline
  alias Jarm.Reactions

  import Canada, only: [can?: 2]

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    if connected?(socket) do
      Timeline.subscribe()
      Reactions.subscribe()
    end

    {:ok,
     assign(socket,
       locale: locale,
       emojis: Reactions.all_emojis()
     )}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    post = Timeline.get_post!(id)
    current_user = socket.assigns.current_user

    socket =
      case current_user |> can?(read(post)) do
        true ->
          comment = %Timeline.Comment{}
          changeset = Timeline.Comment.changeset(comment, %{})

          socket
          |> assign(:page_title, gettext("Jarm details"))
          |> assign(:post, Timeline.get_post!(id))
          |> assign(:changeset, changeset)

        false ->
          socket
          |> put_flash(:error, "You're not allowed to view this post")
          |> push_redirect(
            to: ~p"/#{socket.assigns.locale}",
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
            to: ~p"/#{socket.assigns.locale}",
            replace: true
          )

        false ->
          socket
          |> put_flash(:error, "You're not allowed to delete this post")
          |> push_patch(to: ~p"/#{socket.assigns.locale}/posts/#{id}")
      end

    {
      :noreply,
      socket
    }
  end

  def handle_event("validate", %{"comment" => comment_params}, socket) do
    changeset =
      Timeline.Comment.changeset(%Timeline.Comment{}, comment_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"comment" => comment_params}, socket) do
    current_user = socket.assigns.current_user
    post = socket.assigns.post
    Timeline.create_comment(current_user, post, comment_params)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:comment_created, comment}, socket) do
    if socket.assigns.post.id != comment.post_id do
      {:noreply, socket}
    else
      # Reset the changeset to clear the comment.
      socket = assign(socket, changeset: Timeline.Comment.changeset(%Timeline.Comment{}, %{}))

      new_post = Timeline.get_post!(comment.post_id)
      {:noreply, update(socket, :post, fn _post -> new_post end)}
    end
  end

  @impl true
  def handle_info({:reaction_added, reaction}, socket) do
    post = Timeline.get_post!(reaction.post_id)

    send_update(JarmWeb.LiveComponents.ReactionsLive,
      id: "post-#{post.id}-reactions-component",
      reactions: post.reactions
    )

    {:noreply, socket}
  end

  @impl true
  def handle_info({:reaction_deleted, reaction}, socket) do
    post = Timeline.get_post!(reaction.post_id)

    send_update(JarmWeb.LiveComponents.ReactionsLive,
      id: "post-#{post.id}-reactions-component",
      reactions: post.reactions
    )

    {:noreply, socket}
  end
end
