defmodule InnerCircleWeb.UserInvitationController do
  use InnerCircleWeb, :controller

  alias InnerCircle.Accounts
  alias InnerCircle.Accounts.User

  def new(conn, _params) do
    render(conn, "new.html", changeset: Accounts.change_user_email(%User{}))
  end

  def create(conn, %{"user" => %{"email" => email}}) do
    Accounts.deliver_user_invitation(
      email,
      &Routes.user_registration_url(conn, :new, conn.params["locale"], &1)
    )

    # Regardless of the outcome, show an impartial success/error message.
    conn
    |> put_flash(
      :info,
      "Invitation sent."
    )
    |> render("new.html", changeset: Accounts.change_user_email(%User{}))
  end
end
