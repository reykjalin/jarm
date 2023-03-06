defmodule InnerCircleWeb.LiveHelpers do
  import Phoenix.Component

  alias InnerCircle.Accounts

  def assign_current_user(socket, session) do
    assign_new(
      socket,
      :current_user,
      fn -> Accounts.get_user_by_session_token(session["user_token"]) end
    )
  end
end
