defmodule JarmWeb.PostLive.Index do
  use JarmWeb, :live_view

  alias Jarm.Timeline
  alias Jarm.Timeline.Post
  alias Jarm.Reactions

  import Canada, only: [can?: 2]

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    if connected?(socket), do: Timeline.subscribe()

    posts = Timeline.list_posts()
    first_post = List.first(posts, nil)
    last_post = List.last(posts, nil)

    socket =
      assign(socket,
        posts: posts,
        first_post: first_post,
        last_post: last_post,
        locale: locale,
        emojis: Reactions.all_emojis()
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

  @impl true
  def handle_event("search_emoji", %{"query" => query} = params, socket) do
    emojis =
      case query do
        "" -> Reactions.all_emojis()
        query -> Reactions.search_emojis(query)
      end

    socket =
      socket
      |> assign(emojis: emojis)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "toggle_reaction",
        %{"post" => post_id, "emoji" => emoji_id, "user" => user_id},
        socket
      ) do
    case post_id
         |> Reactions.toggle_reaction(emoji_id, user_id) do
      {:ok, reaction} ->
        IO.inspect(reaction, label: "inserted reaction")

      {:error, changeset} ->
        IO.inspect(changeset, label: "failed changeset")
    end

    {:noreply, socket}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("🌾 The Pasture"))
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
