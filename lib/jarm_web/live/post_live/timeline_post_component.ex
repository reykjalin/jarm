defmodule JarmWeb.PostLive.TimelinePostComponent do
  use JarmWeb, :live_component

  alias Phoenix.LiveView.JS

  alias Jarm.Emojis

  import Canada, only: [can?: 2]

  @impl true
  def handle_event("search_emoji", %{"query" => query}, socket) do
    emojis = case query do
      "" -> Emojis.all_emojis()
      query -> Emojis.search_emojis(query)
    end

    socket =
      socket
      |> assign(emojis: emojis)

    {:noreply, socket}
  end

end
