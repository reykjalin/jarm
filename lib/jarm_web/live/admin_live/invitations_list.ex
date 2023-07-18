defmodule JarmWeb.AdminLive.InvitationsList do
  use JarmWeb, :live_view

  alias Jarm.Administrator

  @impl true
  def mount(%{"locale" => locale}, session, socket) do
    invitations = Administrator.get_all_invitations()
    valid_invitations = Administrator.get_valid_invitations()
    expired_invitations = Administrator.get_expired_invitations()

    socket =
      assign(socket,
        invitations: if(invitations, do: invitations, else: []),
        valid_invitations: if(valid_invitations, do: valid_invitations, else: []),
        expired_invitations: if(expired_invitations, do: expired_invitations, else: []),
        locale: locale
      )

    {:ok, socket}
  end
end
