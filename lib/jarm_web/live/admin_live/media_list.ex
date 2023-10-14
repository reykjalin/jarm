defmodule JarmWeb.AdminLive.MediaList do
  use JarmWeb, :live_view

  alias Jarm.Administrator

  @impl true
  def mount(%{"locale" => locale}, _session, socket) do
    media = Administrator.get_all_media()

    socket =
      assign(socket,
        media: if(media, do: Enum.reverse(media), else: []),
        locale: locale
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-3xl pb-5"><%= gettext("Media") %></h1>

    <.card>
      <details :for={m <- @media} class="py-5 border-b border-solid last:border-none">
        <summary><%= m.id %></summary>
        <p class="my-2">ID: <%= m.id %></p>

        <p class="my-2">
          Post ID: <.link href={~p"/#{@locale}/posts/#{m.post_id}"}><%= m.post_id %></.link>
        </p>

        <div class="my-2">
          <p class="my-1">
            Path to original:
            <span :if={not File.exists?(m.path_to_original)}>
              <.icon name="hero-x-mark" class="text-red-500" />
            </span>
            <span :if={File.exists?(m.path_to_original)}>
              <.icon name="hero-check" class="text-green-500" />
              <.link href={~p"/media/#{m.uuid}"}>[direct link]</.link>
            </span>
          </p>
          <pre class="overflow-auto border border-solid p-2"><%= m.path_to_original %></pre>
        </div>

        <div class="my-2">
          <p class="my-1">
            Path to compressed:
            <span :if={
              m.path_to_compressed == nil or m.path_to_compressed == "" or
                not File.exists?(m.path_to_compressed)
            }>
              <.icon name="hero-x-mark" class="text-red-500" />
            </span>
            <span :if={
              m.path_to_compressed != nil and m.path_to_compressed != "" and
                File.exists?(m.path_to_compressed)
            }>
              <.icon name="hero-check" class="text-green-500" />
              <.link href={~p"/compressed-media/#{m.uuid}"}>[direct link]</.link>
            </span>

            <.button class="bg-green-500">
              <.icon name="hero-arrow-path" />
            </.button>
          </p>
          <pre class="overflow-auto border border-solid p-2"><%= if m.path_to_compressed == nil or m.path_to_compressed == "", do: "-", else: m.path_to_compressed %></pre>
        </div>

        <div :if={String.starts_with?(m.mime_type, "image")} class="my-2">
          <p class="my-1">
            <%= gettext("Path to thumbnail") %>:
            <span :if={
              m.path_to_thumbnail == nil or m.path_to_thumbnail == "" or
                not File.exists?(m.path_to_thumbnail)
            }>
              <.icon name="hero-x-mark" class="text-red-500" />
            </span>
            <span :if={
              m.path_to_thumbnail != nil and m.path_to_thumbnail != "" and
                File.exists?(m.path_to_thumbnail)
            }>
              <.icon name="hero-check" class="text-green-500" />
              <.link href={~p"/thumbnail/#{m.uuid}"}>[direct link]</.link>
            </span>
            <.button class="bg-green-500">
              <.icon name="hero-arrow-path" />
            </.button>
          </p>
          <pre class="overflow-auto border border-solid p-2"><%= if m.path_to_thumbnail == nil or m.path_to_thumbnail == "", do: "-", else: m.path_to_thumbnail %></pre>
        </div>

        <div class="my-2">
          <p>
            <%= gettext("LQIP") %>:
            <.icon :if={m.lqip == nil or m.lqip == ""} name="hero-x-mark" class="text-red-500" />
            <.icon :if={m.lqip != nil and m.lqip != ""} name="hero-check" class="text-green-500" />
            <.button class="bg-green-500">
              <.icon name="hero-arrow-path" />
            </.button>
          </p>
        </div>
      </details>
    </.card>
    """
  end
end
