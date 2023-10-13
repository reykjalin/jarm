defmodule JarmWeb.AdminLive.MediaList do
  use JarmWeb, :live_view

  alias Jarm.Administrator

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    media = Administrator.get_all_media()

    socket =
      assign(socket,
        media: if(media, do: media, else: []),
        locale: locale
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl pb-5"><%= gettext("Media") %></h1>

    <.card>
      <.table id="media" rows={@media}>
        <:col :let={m} label={gettext("ID")}><%= m.id %></:col>
        <:col :let={m} label={gettext("Post ID")}>
          <.link href={~p"/#{@locale}/posts/#{m.post_id}"}><%= m.post_id %></.link>
        </:col>
        <:col :let={m} label={gettext("MIME type")}><%= m.mime_type %></:col>
        <:col :let={m} label={gettext("Size")}><%= m.width %>x<%= m.height %></:col>
        <:col :let={m} label={gettext("Path to original")}>
          <.icon :if={not File.exists?(m.path_to_original)} name="hero-x-mark" class="text-red-500" />
          <.icon :if={File.exists?(m.path_to_original)} name="hero-check" class="text-green-500" />
          <code>
            <%= m.path_to_original %>
          </code>
        </:col>
        <:col :let={m} label={gettext("Path to compressed")}>
          <.icon
            :if={
              m.path_to_compressed == nil or m.path_to_compressed == "" or
                not File.exists?(m.path_to_compressed)
            }
            name="hero-x-mark"
            class="text-red-500"
          />
          <.icon
            :if={
              m.path_to_compressed != nil and m.path_to_compressed != "" and
                File.exists?(m.path_to_compressed)
            }
            name="hero-check"
            class="text-green-500"
          />
          <code>
            <%= if m.path_to_compressed == nil or m.path_to_compressed == "",
              do: "-",
              else: m.path_to_compressed %>
          </code>
        </:col>
        <:col :let={m} label={gettext("Path to thumbnail")}>
          <.icon
            :if={
              m.path_to_thumbnail == nil or m.path_to_thumbnail == "" or
                not File.exists?(m.path_to_thumbnail)
            }
            name="hero-x-mark"
            class="text-red-500"
          />
          <.icon
            :if={
              m.path_to_thumbnail != nil and m.path_to_thumbnail != "" and
                File.exists?(m.path_to_thumbnail)
            }
            name="hero-check"
            class="text-green-500"
          />
          <code>
            <%= if m.path_to_thumbnail == nil or m.path_to_thumbnail == "",
              do: "-",
              else: m.path_to_thumbnail %>
          </code>
        </:col>
        <:col :let={m} label={gettext("LQIP")}>
          <.icon :if={m.lqip == nil or m.lqip == ""} name="hero-x-mark" class="text-red-500" />
          <.icon :if={m.lqip != nil and m.lqip != ""} name="hero-check" class="text-green-500" />
        </:col>
      </.table>
    </.card>
    """
  end
end
