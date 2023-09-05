defmodule JarmWeb.UserSettingsLive do
  use JarmWeb, :live_view

  alias Jarm.Accounts

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      <%= gettext("Account Settings") %>
      <:subtitle>
        <%= gettext("Manage your account display name, email address, and password settings") %>
      </:subtitle>
    </.header>

    <.card>
      <h2 class="text-lg text-center mb-5"><%= gettext("Change your profile picture") %></h2>

      <h3 calss="my-5 text-md"><%= gettext("Upload your own") %></h3>

      <.button class="m-auto" phx-disable-with={gettext("Generating…")}>
        <%= gettext("Upload") %>
      </.button>

      <h3 calss="my-5 text-md"><%= gettext("Gravatar") %></h3>

      <div class="flex gap-5 justify-center">
        <img
          class="border border-zinc-400"
          src={ "https://gravatar.com/avatar/#{@email_hash}?d=mp" }
          width="100"
          height="100"
        />
        <img
          class="border border-zinc-400"
          src={ "https://gravatar.com/avatar/#{@email_hash}?d=identicon&f=y&s=100" }
          width="100"
          height="100"
        />
        <img
          class="border border-zinc-400"
          src={ "https://gravatar.com/avatar/#{@email_hash}?d=monsterid&f=y&s=100" }
          width="100"
          height="100"
        />
        <img
          class="border border-zinc-400"
          src={ "https://gravatar.com/avatar/#{@email_hash}?d=wavatar&f=y&s=100" }
          width="100"
          height="100"
        />
        <img
          class="border border-zinc-400"
          src={ "https://gravatar.com/avatar/#{@email_hash}?d=retro&f=y&s=100" }
          width="100"
          height="100"
        />
        <img
          class="border border-zinc-400"
          src={ "https://gravatar.com/avatar/#{@email_hash}?d=robohash&f=y&s=100" }
          width="100"
          height="100"
        />
      </div>

      <h3 calss="my-5 text-md"><%= gettext("Your cat avatars") %></h3>

      <div class="flex gap-5 justify-center">
        <img
          class="border border-zinc-400"
          src={~p"/users/#{@current_user.id}/avatar/email_cat"}
          width="100"
          height="100"
        />
        <img
          class="border border-zinc-400"
          src={~p"/users/#{@current_user.id}/avatar/name_cat"}
          width="100"
          height="100"
        />
      </div>

      <.button class="m-auto" phx-disable-with={gettext("Generating…")}>
        <%= gettext("Generate your own cat 😻") %>
      </.button>
    </.card>

    <.card>
      <h2 class="text-lg text-center"><%= gettext("Change your display name") %></h2>

      <.simple_form
        for={@display_name_form}
        id="display_name_form"
        phx-submit="update_display_name"
        phx-change="validate_display_name"
      >
        <.input
          field={@display_name_form[:display_name]}
          type="text"
          label={gettext("New display name")}
        />
        <.input
          field={@display_name_form[:current_password]}
          name="current_password"
          id="current_password_for_display_name"
          type="password"
          label={gettext("Current password")}
          value={@display_name_form_current_password}
          required
        />
        <:actions>
          <.button phx-disable-with={gettext("Changing…")}>
            <%= gettext("Change display name") %>
          </.button>
        </:actions>
      </.simple_form>
    </.card>

    <.card>
      <h2 class="text-lg text-center"><%= gettext("Change your email") %></h2>

      <.simple_form
        for={@email_form}
        id="email_form"
        phx-submit="update_email"
        phx-change="validate_email"
      >
        <.input field={@email_form[:email]} type="email" label={gettext("Email")} required />
        <.input
          field={@email_form[:current_password]}
          name="current_password"
          id="current_password_for_email"
          type="password"
          label={gettext("Current password")}
          value={@email_form_current_password}
          required
        />
        <:actions>
          <.button phx-disable-with={gettext("Changing…")}><%= gettext("Change email") %></.button>
        </:actions>
      </.simple_form>
    </.card>

    <.card>
      <h2 class="text-lg text-center"><%= gettext("Change your password") %></h2>

      <.simple_form
        for={@password_form}
        id="password_form"
        action={~p"/#{@locale}/users/log_in?_action=password_updated"}
        method="post"
        phx-change="validate_password"
        phx-submit="update_password"
        phx-trigger-action={@trigger_submit}
      >
        <.input
          field={@password_form[:email]}
          type="hidden"
          id="hidden_user_email"
          value={@current_email}
        />
        <.input
          field={@password_form[:password]}
          type="password"
          label={gettext("New password")}
          required
        />
        <.input
          field={@password_form[:password_confirmation]}
          type="password"
          label={gettext("Confirm new password")}
        />
        <.input
          field={@password_form[:current_password]}
          name="current_password"
          type="password"
          label={gettext("Current password")}
          id="current_password_for_password"
          value={@current_password}
          required
        />
        <:actions>
          <.button phx-disable-with={gettext("Changing…")}>
            <%= gettext("Change password") %>
          </.button>
        </:actions>
      </.simple_form>
    </.card>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, "Email changed successfully.")

        :error ->
          put_flash(socket, :error, "Email change link is invalid or it has expired.")
      end

    {:ok, push_navigate(socket, to: ~p"/#{socket.assigns.locale}/users/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    email_changeset = Accounts.change_user_email(user)
    password_changeset = Accounts.change_user_password(user)
    display_name_changeset = Accounts.change_user_display_name(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:email_form_current_password, nil)
      |> assign(:display_name_form_current_password, nil)
      |> assign(:current_email, user.email)
      |> assign(:email_form, to_form(email_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:display_name_form, to_form(display_name_changeset))
      |> assign(:trigger_submit, false)
      |> assign(:generated_avatar, nil)
      |> assign(
        :email_hash,
        :crypto.hash(:md5, user.email) |> Base.encode16() |> String.downcase()
      )

    {:ok, socket}
  end

  def handle_event("validate_display_name", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    display_name_form =
      socket.assigns.current_user
      |> Accounts.change_user_display_name(user_params)
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply,
     assign(socket,
       display_name_form: display_name_form,
       display_name_form_current_password: password
     )}
  end

  def handle_event("update_display_name", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_display_name(user, password, user_params) do
      {:ok, _user} ->
        info = gettext("Display name successfully updated.")
        {:noreply, socket |> put_flash(:info, info) |> assign(display_name_current_password: nil)}

      {:error, changeset} ->
        {:noreply,
         assign(socket, :display_name_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    email_form =
      socket.assigns.current_user
      |> Accounts.change_user_email(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, email_form: email_form, email_form_current_password: password)}
  end

  def handle_event("update_email", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, applied_user} ->
        Accounts.deliver_update_email_instructions(
          applied_user,
          user.email,
          &url(~p"/#{socket.assigns.locale}/users/settings/confirm_email/#{&1}")
        )

        info = gettext("A link to confirm your email change has been sent to the new address.")
        {:noreply, socket |> put_flash(:info, info) |> assign(email_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, :email_form, to_form(Map.put(changeset, :action, :insert)))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
