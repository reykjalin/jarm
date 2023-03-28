defmodule InnerCircleWeb.MediaLive.Index do
  use InnerCircleWeb, :live_view

  alias InnerCircle.MediaManagement
  alias InnerCircle.Timeline
  alias InnerCircle.Timeline.Post

  import Canada, only: [can?: 2]

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Timeline.subscribe()

    socket = assign_current_user(socket, session)
    current_user = socket.assigns.current_user

    media = MediaManagement.list_media_for_user(current_user)

    socket =
      assign(socket,
        media: media
      )

    {:ok, socket}
  end
end
