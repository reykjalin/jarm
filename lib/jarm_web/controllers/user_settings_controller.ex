defmodule JarmWeb.UserSettingsController do
  use JarmWeb, :controller

  alias Jarm.Accounts

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/#{conn.params["locale"]}/users/settings")

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/#{conn.params["locale"]}/users/settings")
    end
  end
end
