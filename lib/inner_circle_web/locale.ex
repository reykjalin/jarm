defmodule InnerCircleWeb.Locale do
  alias Plug.Conn

  @locales Gettext.known_locales(InnerCircleWeb.Gettext)
  @cookie "jarm_locale"
  @ten_days 10 * 24 * 60 * 60

  def set_locale_cookie(conn, opts) do
    locale = Gettext.get_locale(opts[:gettext])

    IO.inspect(locale, label: "current locale")

    persist_locale(conn, locale)
  end

  defp persist_locale(%Conn{cookies: %{@cookie => saved_locale}} = conn, new_locale) do
    if new_locale != saved_locale do
      IO.inspect(new_locale, label: "persisting locale")
      Conn.put_resp_cookie(conn, @cookie, new_locale, max_age: @ten_days)
    else
      conn
    end
  end

  defp persist_locale(conn, nil), do: conn

  defp persist_locale(conn, locale) do
    IO.inspect(locale, label: "persisting locale")
    Conn.put_resp_cookie(conn, @cookie, locale, max_age: @ten_days)
  end
end
