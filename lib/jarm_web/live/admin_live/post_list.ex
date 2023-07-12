defmodule JarmWeb.AdminLive.PostList do
  use JarmWeb, :live_view

  alias Jarm.Timeline

  @impl true
  def mount(%{"locale" => locale}, session, socket) do
    socket = assign_current_user(socket, session)

    posts = Timeline.list_all_posts()
    IO.inspect(posts, label: "all posts")

    socket =
      assign(socket,
        posts: (if posts, do: posts, else: []),
        locale: locale
      )

    {:ok, socket}
  end

end
