defmodule JarmWeb.UserSettingsController do
  use JarmWeb, :controller

  alias Jarm.Accounts
  alias JarmWeb.UserAuth

  plug :assign_display_name_email_and_password_changesets

  def edit(conn, _params) do
    render(conn, "edit.html")
  end

  def update(conn, %{"action" => "update_display_name"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    IO.inspect(user_params, label: "updated display name")
    IO.inspect(user, label: "current user")

    case Accounts.update_user_display_name(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Display name updated successfully.")
        |> put_session(
          :user_return_to,
          Routes.user_settings_path(conn, :edit, conn.params["locale"])
        )
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", display_name_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    %Accounts.User{} = user = conn.assigns.current_user

    IO.inspect(user_params, label: "updated email")

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &Routes.user_settings_url(conn, :confirm_email, conn.params["locale"], &1)
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit, conn.params["locale"]))

      {:error, changeset} ->
        render(conn, "edit.html", email_changeset: changeset)
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    IO.inspect(user_params, label: "updated password")

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(
          :user_return_to,
          Routes.user_settings_path(conn, :edit, conn.params["locale"])
        )
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit.html", password_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_user, token) do
      :ok ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: Routes.user_settings_path(conn, :edit, conn.params["locale"]))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.user_settings_path(conn, :edit, conn.params["locale"]))
    end
  end

  defp assign_display_name_email_and_password_changesets(conn, _opts) do
    user = conn.assigns.current_user

    conn
    |> assign(:display_name_changeset, Accounts.change_user_display_name(user))
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:password_changeset, Accounts.change_user_password(user))
  end
end
