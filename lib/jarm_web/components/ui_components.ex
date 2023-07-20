defmodule JarmWeb.UiComponents do
  use Phoenix.Component

  alias Phoenix.LiveView.JS

  import JarmWeb.Gettext
  import JarmWeb.CoreComponents

  alias Jarm.Timeline.Post
  alias Jarm.Reactions.Emoji

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={[
      "my-5 p-5 md:p-10 border border-zinc-400 rounded-md bg-slate-800 light:bg-white",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :current_user, Jarm.Accounts.User, required: true
  attr :post, Post, required: true
  attr :emojis, :list, default: []

  def emoji_selector(assigns) do
    ~H"""
    <div class="flex flex-row gap-5 items-center">
      <button
        class="py-2 px-2 md:py-2 md:px-3 light:hover:bg-slate-100 hover:bg-slate-600 rounded border hover:border-slate-400"
        phx-click={
          JS.toggle(
            to: "#post-#{@post.id}-reactions",
            in: {"ease-out duration-75", "opacity-0", "opacity-100"}
          )
          |> JS.remove_class("hidden", to: "#post-#{@post.id}-reactions")
          |> JS.focus(to: "#post-#{@post.id}-reactions-search-bar")
        }
      >
        ❤️+
      </button>

      <div>
        <%= for {emoji, reactions} <- @post.reactions |> Enum.group_by(fn r -> r.emoji.emoji end, fn r -> r end) do %>
          <button
            class={[
              "py-2 px-2 md:py-2 md:px-3 light:hover:bg-slate-100 hover:bg-slate-600 rounded-full border hover:border-slate-400",
              "#{if Enum.find(reactions, fn r -> r.user_id == @current_user.id end), do: "bg-sky-800"}"
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
                  post: @post.id,
                  user: @current_user.id
                }
              )
              |> JS.hide(to: "#post-#{@post.id}-reactions")
            }
          >
            <%= emoji %> <%= length(reactions) %>
          </button>
        <% end %>
      </div>
    </div>

    <div
      class="relative hidden"
      id={"post-#{@post.id}-reactions"}
      phx-click-away={
        JS.hide(
          to: "#post-#{@post.id}-reactions",
          transition: {"ease-out duration-75", "opacity-100", "opacity-0"}
        )
        |> JS.add_class("hidden", to: "#post-#{@post.id}-reactions")
      }
    >
      <.form :let={f} phx-change="search_emoji" phx-debounce="100">
        <div class="fixed z-50 bottom-0 left-0 right-0 md:bottom-12 md:absolute border-t md:border border-black rounded-t md:rounded shadow-[0_0_6px_-1px_rgb(0,0,0,0.1),0_0_4px_-2px_rgb(0,0,0,0.1)] shadow-black bg-slate-800 light:bg-white w-full h-[50vh] md:max-w-[600px] md:max-h-[300px] overflow-auto">
          <.input field={f[:post_id]} type="hidden" value={@post.id} />
          <div class="sticky w-full top-0 p-3 md:p-5 z-50 bg-slate-800 light:bg-white border-b">
            <.input
              id={"post-#{@post.id}-reactions-search-bar"}
              field={f[:query]}
              type="text"
              class="w-full"
              placeholder={gettext("Search…")}
            />
          </div>
          <div class="text-center">
            <%= for emoji <- @emojis do %>
              <button
                type="button"
                class="m-1 py-2 px-3 rounded light:hover:bg-slate-100 hover:bg-slate-600 text-2xl"
                phx-click={
                  JS.push("toggle_reaction",
                    value: %{emoji: emoji.id, post: @post.id, user: @current_user.id}
                  )
                  |> JS.hide(to: "#post-#{@post.id}-reactions")
                }
              >
                <%= emoji.emoji %>
              </button>
            <% end %>
          </div>
        </div>
      </.form>
    </div>
    """
  end
end
