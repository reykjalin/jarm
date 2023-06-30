defmodule JarmWeb.MediaLive.Index do
  use JarmWeb, :live_view

  alias Jarm.MediaManagement
  alias Jarm.Timeline

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Timeline.subscribe()

    socket = assign_current_user(socket, session)
    current_user = socket.assigns.current_user

    media = MediaManagement.list_media_for_user(current_user)

    socket =
      assign(socket,
        media: media,
        page_title: gettext("🛖 The Barn")
      )

    {:ok, socket}
  end
end
