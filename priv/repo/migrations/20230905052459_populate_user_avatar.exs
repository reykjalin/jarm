defmodule Jarm.Repo.Migrations.PopulateUserAvatar do
  use Ecto.Migration

  alias Jarm.Repo

  def up do
    import Ecto.Query, only: [from: 2]

    from("users", select: [:id, :email, :display_name])
    |> Repo.all()
    |> Enum.each(fn u ->
      media_path = System.get_env("MEDIA_FILE_STORAGE", "priv/static/media")
      email_cat = Path.join(media_path, "email-cat-#{u.id}.webp")
      name_cat = Path.join(media_path, "name-cat-#{u.id}.webp")

      AvatarGenerators.Cat.build_cat(email_cat, u.email)
      AvatarGenerators.Cat.build_cat(name_cat, u.display_name)

      from(config in "user_configuration", where: config.user_id == ^u.id)
      |> Repo.update_all(
        set: [email_cat_avatar_path: email_cat, display_name_cat_avatar_path: name_cat]
      )
    end)
  end

  def down do
    # Nothing to do.
  end
end
