defmodule JarmWeb.LiveHelpers do
  alias Jarm.Timeline.Post

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
    # Try to find a matching translation for the current user's locale.
    case Enum.find(translations, fn t -> t.locale == user_locale end) do
      nil ->
        # If translation in current user's locale doesn't exist, use the english locale if it exists.
        if post_locale == "en" do
          get_locale_representation(post_locale)
        else
          case Enum.find(translations, fn t -> t.locale == "en" end) do
            nil ->
              # No English translation so we use the post locale representation.
              get_locale_representation(post_locale)

            translation ->
              get_locale_representation(translation.locale)
          end
        end

      translation ->
        get_locale_representation(translation.locale)
    end
  end

  def get_post_body_for_locale(%Post{:body => body, :locale => post_locale}, locale)
      when post_locale == locale,
      do: body

  def get_post_body_for_locale(%Post{:body => body, :translations => translations}, locale) do
    # Try to find a matching translation for the current user's locale.
    case Enum.find(translations, fn t -> t.locale == locale end) do
      nil ->
        # If translation in current user's locale doesn't exist, use the english translation if it exists.
        if locale == "en" do
          body
        else
          case Enum.find(translations, fn t -> t.locale == "en" end) do
            nil ->
              body

            translation ->
              translation.body
          end
        end

      translation ->
        translation.body
    end
  end
end
