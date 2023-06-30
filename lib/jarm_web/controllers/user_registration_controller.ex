defmodule JarmWeb.UserRegistrationController do
  use JarmWeb, :controller

  alias Jarm.Accounts
  alias Jarm.Accounts.User
  alias JarmWeb.UserAuth

  def new(conn, %{"token" => token}) do
    case Accounts.verify_invitation(token) do
      {:ok, email} ->
        user = %User{email: email}
        changeset = Accounts.change_user_registration(user)
        render(conn, "new.html", %{changeset: changeset, token: token})

      :error ->
        conn
        |> put_flash(:error, "User invitation link is invalid or it has expired.")
        |> redirect(to: "/")
    end
  end

  def create(conn, %{"user" => user_params, "token" => token}) do
    case Accounts.verify_invitation(token) do
      {:ok, _email} ->
        case Accounts.register_user(user_params) do
          {:ok, user} ->
            # Delete the token
            Accounts.confirm_user(token)

            conn
            |> put_flash(:info, "User created successfully.")
            |> UserAuth.log_in_user(user)

          {:error, %Ecto.Changeset{} = changeset} ->
            render(conn, "new.html", %{changeset: changeset, token: token})
        end

      :error ->
        conn
        |> put_flash(:error, "User invitation link is invalid or it has expired.")
        |> redirect(to: "/")
    end
  end
end
