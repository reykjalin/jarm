defmodule JarmWeb.UserListLive.Index do
  use JarmWeb, :live_view

  alias Jarm.Accounts

  @impl true
  def mount(%{"locale" => locale}, session, socket) do
    socket = assign_current_user(socket, session)

    users = Accounts.get_all_users()

    socket =
      assign(socket,
        users: users,
        locale: locale
      )

    {:ok, socket}
  end

end
