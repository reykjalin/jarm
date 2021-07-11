defmodule InnerCircleWeb.PostLive.Index do
  use InnerCircleWeb, :live_view

  alias InnerCircle.Timeline
  alias InnerCircle.Timeline.Post

  import Canada, only: [can?: 2]

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Timeline.subscribe()

    socket = assign_current_user(socket, session)

    posts = Timeline.list_posts()
    first_post = List.first(posts, nil)
    last_post = List.last(posts, nil)

    socket =
      assign(socket,
        posts: posts,
        first_post: first_post,
        last_post: last_post
      )

    {:ok, socket, temporary_assigns: [posts: []]}
  end

  @impl true
  def handle_params(%{"older_than" => post}, _url, socket) do
    post = String.to_integer(post)
    post = Timeline.get_post!(post)

    posts = Timeline.list_posts_older_than(post)
    first_post = List.first(posts, nil)
    last_post = List.last(posts, nil)

    socket =
      assign(socket,
        posts: posts,
        first_post: first_post,
        last_post: last_post
      )

    {:noreply, socket}
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
    |> assign(:page_title, "Timeline")
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({:post_created, _post}, socket) do
    # We don't broadcast creations.
    # TODO: broadcast creation to trigger a "show newer posts" link.
    {:noreply, socket}
  end

  @impl true
  def handle_info({:post_updated, post}, socket) do
    {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
  end

  @impl true
  def handle_info({:post_deleted, post}, socket) do
    {:noreply, update(socket, :posts, fn posts -> [post | posts] end)}
  end
end
