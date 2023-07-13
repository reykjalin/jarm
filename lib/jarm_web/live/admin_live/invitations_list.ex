defmodule JarmWeb.AdminLive.InvitationsList do
  use JarmWeb, :live_view

  alias Jarm.Administrator

  @impl true
  def mount(%{"locale" => locale}, session, socket) do
    socket = assign_current_user(socket, session)

    invitations = Administrator.get_all_invitations()

    socket =
      assign(socket,
        invitations: if(invitations, do: invitations, else: []),
        locale: locale
      )

    {:ok, socket}
  end
end
