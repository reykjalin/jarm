defmodule InnerCircleWeb.LiveHelpers do
  import Phoenix.Component

  alias InnerCircle.Accounts
  alias InnerCircle.Timeline.Post

  def assign_current_user(socket, session) do
    assign_new(
      socket,
      :current_user,
      fn -> Accounts.get_user_by_session_token(session["user_token"]) end
    )
  end

  def get_post_locale(%Post{:locale => locale}) do
    case locale do
      "en" -> "🇺🇸 English"
      "is" -> "🇮🇸 Íslenska"
      "fil" -> "🇵🇭 Filipino"
      _ -> locale
    end
  end
end
