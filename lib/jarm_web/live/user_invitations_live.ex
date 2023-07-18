defmodule JarmWeb.UserInvitationsLive do
  use JarmWeb, :live_view

  alias Jarm.Accounts
  alias Jarm.Accounts.User

  def render(assigns) do
    ~H"""
    <h1 class="text-3xl"><%= gettext("Send an invitation") %></h1>

    <.card>
      <.header class="text-center">
        <%= gettext("Send an invitation") %>
      </.header>

      <.simple_form
        for={@form}
        id="invitation_form"
        action={~p"/#{@locale}/users/invite"}
        phx-submit="send_invitation"
        phx-change="validate"
      >
        <.input field={@form[:email]} type="email" label={gettext("Email")} required autofocus />

        <:actions>
          <.button phx-disable-with={gettext("Sending invite…")} class="w-full">
            <%= gettext("Send invite") %>
          </.button>
        </:actions>
      </.simple_form>
    </.card>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(Accounts.change_user_email(%User{}), as: "email")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end

  def handle_event("validate", %{"email" => email_params}, socket) do
    changeset = Accounts.change_user_email(%User{}, email_params)

    socket =
      assign(
        socket,
        form: to_form(Map.put(changeset, :action, :validate), as: "email")
      )

    {:noreply, socket}
  end

  def handle_event("send_invitation", %{"email" => %{"email" => email}}, socket) do
    case Accounts.deliver_user_invitation(
           email,
           &~p"/#{socket.assigns.locale}/users/register/#{&1}"
         ) do
      {:ok, _email} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Invitation sent successfully."))
         |> redirect(to: ~p"/#{socket.assigns.locale}/users/invite")}

      {:error, error} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to send inviation:") <> error)}
    end
  end
end
