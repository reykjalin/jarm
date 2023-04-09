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

  def get_locale_representation(locale) do
    case locale do
      "en" -> "🇺🇸 English"
      "is" -> "🇮🇸 Íslenska"
      "fil" -> "🇵🇭 Filipino"
      _ -> locale
    end
  end

  def get_locale_for_translated_post(%Post{:locale => post_locale}, user_locale)
      when post_locale == user_locale,
      do: get_locale_representation(post_locale)

  def get_locale_for_translated_post(
        %Post{:locale => post_locale, :translations => translations},
        user_locale
      ) do
    case Enum.find(translations, fn t -> t.locale == user_locale end) do
      nil ->
        get_locale_representation(post_locale)

      translation ->
        get_locale_representation(translation.locale)
    end
  end

  def get_post_body_for_locale(%Post{:body => body, :locale => post_locale}, locale)
      when post_locale == locale,
      do: body

  def get_post_body_for_locale(%Post{:body => body, :translations => translations}, locale) do
    case Enum.find(translations, fn t -> t.locale == locale end) do
      nil ->
        body

      translation ->
        translation.body
    end
  end
end
