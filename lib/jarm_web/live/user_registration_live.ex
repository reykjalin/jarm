defmodule JarmWeb.UserRegistrationLive do
  use JarmWeb, :live_view

  alias Jarm.Accounts
  alias Jarm.Accounts.User

  def render(assigns) do
    ~H"""
    <.card>
      <.header class="text-center">
        <%= gettext("Register for an account") %>
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Sign in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/#{@locale}/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          <%= gettext("Oops, something went wrong! Please check the errors below.") %>
        </.error>

        <.input
          field={@form[:display_name]}
          type="text"
          label={gettext("Display Name")}
          required={true}
          autofocus={true}
        />
        <.input field={@form[:email]} type="email" label={gettext("Email")} required />
        <.input field={@form[:password]} type="password" label={gettext("Password")} required />
        <.input field={@form[:token]} type="hidden" value={@token} />

        <:actions>
          <.button phx-disable-with={gettext("Creating account…")} class="w-full">
            <%= gettext("Create an account") %>
          </.button>
        </:actions>
      </.simple_form>
    </.card>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    case Accounts.verify_invitation(token) do
      {:ok, email} ->
        user = %User{email: email}
        changeset = Accounts.change_user_registration(user)

        socket =
          socket
          |> assign(trigger_submit: false, check_errors: false, token: token)
          |> assign_form(changeset)

        {:ok, socket, temporary_assigns: [form: nil]}

      :error ->
        {:ok,
         socket
         |> put_flash(:error, gettext("User invitation link is invalid or it has expired."))
         |> redirect(to: ~p"/#{socket.assigns.locale}/users/log_in")}
    end
  end

  def handle_event("save", %{"user" => %{"token" => token} = user_params}, socket) do
    socket =
      case Accounts.verify_invitation(token) do
        {:ok, _email} ->
          IO.inspect("token valid")

          case Accounts.register_user(user_params) do
            {:ok, user} ->
              IO.inspect("user registered")
              # Delete token.
              Accounts.confirm_user(token)

              changeset = Accounts.change_user_registration(user)
              socket |> assign(trigger_submit: true) |> assign_form(changeset)

            {:error, %Ecto.Changeset{} = changeset} ->
              IO.inspect("failed to register user")
              IO.inspect(changeset, label: "failed changeset")
              socket |> assign(check_errors: true) |> assign_form(changeset)
          end

        :error ->
          IO.inspect("token invalid")
          # TODO: return error
          socket
          |> put_flash(:error, gettext("User invitation link is invalid or it has expired."))
          |> redirect(to: ~p"/#{socket.assigns.locale}/users/log_in")
      end

    {:noreply, socket}

    # case Accounts.register_user(user_params) do
    #   {:ok, user} ->
    #     {:ok, _} =
    #       Accounts.deliver_user_confirmation_instructions(
    #         user,
    #         &url(~p"/#{socket.assigns.locale}/users/confirm/#{&1}")
    #       )

    #     changeset = Accounts.change_user_registration(user)
    #     {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

    #   {:error, %Ecto.Changeset{} = changeset} ->
    #     {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    # end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
