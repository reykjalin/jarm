defmodule JarmWeb.UserLoginLive do
  use JarmWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col border border-zinc-400 rounded-md p-10 my-10 bg-slate-800 light:bg-white">
      <.header class="text-center">
        <%= gettext("Sign in to account") %>
      </.header>

      <.simple_form
        for={@form}
        id="login_form"
        action={~p"/#{@locale}/users/log_in"}
        phx-update="ignore"
      >
        <.input field={@form[:email]} type="email" label={gettext("Email")} required />
        <.input field={@form[:password]} type="password" label={gettext("Password")} required />

        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label={gettext("Keep me logged in")} />
          <.link href={~p"/#{@locale}/users/reset_password"} class="text-sm font-semibold">
            <%= gettext("Forgot your password?") %>
          </.link>
        </:actions>
        <:actions>
          <.button phx-disable-with={gettext("Signing in…")} class="w-full">
            <%= gettext("Sign in") %> <span aria-hidden="true">→</span>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
