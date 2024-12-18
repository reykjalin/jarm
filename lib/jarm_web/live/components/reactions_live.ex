defmodule JarmWeb.LiveComponents.ReactionsLive do
  use JarmWeb, :live_component

  alias Jarm.Reactions

  @impl true
  def render(assigns) do
    ~H"""
    <div class="my-5">
      <div
        class="relative hidden"
        id={"post-#{@post_id}-reactions"}
        phx-click-away={
          JS.hide(
            to: "#post-#{@post_id}-reactions",
            transition: {"ease-out duration-200", "opacity-100", "opacity-0"},
            time: 100
          )
        }
      >
        <div class="z-50 fixed md:absolute bottom-0 left-0 right-0 md:bottom-1 border-t md:border border-zinc-400 rounded-t md:rounded shadow-[0_0_20px_0_rgb(0,0,0,0.3)] bg-slate-800 light:bg-white w-full h-[50vh] md:max-w-[600px] md:max-h-[300px] overflow-auto">
          <.input name="post_id" type="hidden" value={@post_id} />
          <div class="sticky w-full top-0 p-3 md:p-5 z-50 bg-slate-800 light:bg-white border-b">
            <.input
              id={"post-#{@post_id}-reactions-search-bar"}
              name="query"
              type="text"
              class="w-full"
              placeholder={gettext("Search…")}
              value=""
              phx-target={@myself}
              phx-keyup="search_emoji"
            />
          </div>
          <div class="text-center">
            <%= for emoji <- @emojis do %>
              <button
                type="button"
                class="m-1 py-2 px-3 rounded light:hover:bg-slate-100 hover:bg-slate-600 text-2xl"
                phx-click={
                  JS.push(
                    "toggle_reaction",
                    value: %{emoji: emoji.id, post: @post_id, user: @current_user.id},
                    target: @myself
                  )
                  |> JS.hide(
                    to: "#post-#{@post_id}-reactions",
                    transition: {"ease-out duration-200", "opacity-100", "opacity-0"},
                    time: 100
                  )
                }
              >
                <%= emoji.emoji %>
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <div class="flex flex-row gap-5 items-center">
        <button
          class="my-1 py-2 px-2 md:py-2 md:px-3 light:hover:bg-slate-100 hover:bg-slate-600 rounded border hover:border-slate-400 whitespace-nowrap"
          phx-click={
            JS.toggle(
              to: "#post-#{@post_id}-reactions",
              in: {"ease-out duration-200", "opacity-0", "opacity-100"},
              out: {"ease-out duration-200", "opacity-100", "opacity-0"},
              time: 100
            )
            |> JS.focus(to: "#post-#{@post_id}-reactions-search-bar")
          }
        >
          ❤️+
        </button>

        <div>
          <%= for {emoji, reactions} <- @reactions |> Enum.group_by(fn r -> r.emoji.emoji end, fn r -> r end) do %>
            <button
              class={[
                "my-1 py-2 px-2 md:py-2 md:px-3 light:hover:bg-slate-100 hover:bg-slate-600 rounded-full border hover:border-slate-400",
                "#{if Enum.find(reactions, fn r -> r.user_id == @current_user.id end), do: "bg-sky-700 border-sky-700 light:border-sky-400 light:bg-sky-200"}"
              ]}
              title={
                reactions
                |> Enum.map(fn r -> r.user.display_name end)
                |> Enum.reduce(fn n, acc -> "#{acc}, #{n}" end)
              }
              phx-click={
                JS.push("toggle_reaction",
                  value: %{
                    emoji: List.first(reactions).emoji.id,
                    post: @post_id,
                    user: @current_user.id
                  },
                  target: @myself
                )
                |> JS.hide(
                  to: "#post-#{@post_id}-reactions",
                  transition: {"ease-out duration-200", "opacity-100", "opacity-0"},
                  time: 100
                )
              }
            >
              <%= emoji %> <%= length(reactions) %>
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("search_emoji", %{"value" => query}, socket) do
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
  def handle_event("toggle_reaction", params, socket) do
    %{"post" => post_id, "emoji" => emoji_id, "user" => user_id} = params

    post_id
    |> Reactions.toggle_reaction(emoji_id, user_id)

    {:noreply, socket}
  end
end
