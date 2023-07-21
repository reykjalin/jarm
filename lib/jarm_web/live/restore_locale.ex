defmodule JarmWeb.RestoreLocale do
  def on_mount(:default, %{"locale" => locale}, _session, socket) do
    IO.inspect(socket, label: "restore locale socket")
    Gettext.put_locale(JarmWeb.Gettext, locale)
    socket = Phoenix.Component.assign(socket, locale: locale)
    {:cont, socket}
  end

  # catch-all case
  def on_mount(:default, _params, _session, socket), do: {:cont, socket}
end
