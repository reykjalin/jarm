defmodule JarmWeb.AdminLive.UserList do
  use JarmWeb, :live_view

  alias Jarm.Accounts
  alias Jarm.Accounts.User

  @impl true
  def mount(%{"locale" => locale}, session, socket) do
    users = Accounts.get_all_users()

    socket =
      assign(socket,
        users: users,
        locale: locale
      )

    {:ok, socket}
  end
end
