defmodule JarmWeb.PostLive.TimelinePostComponent do
  use JarmWeb, :live_component

  alias Phoenix.LiveView.JS

  alias Jarm.Reactions

  import Canada, only: [can?: 2]

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
end
