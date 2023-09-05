defmodule Jarm.Repo.Migrations.AddUserConfiguration do
  use Ecto.Migration

  def change do
    create table(:user_configuration) do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:avatar, :string, default: "")
      add(:email_cat_avatar_path, :string, default: "")
      add(:display_name_cat_avatar_path, :string, default: "")
      add(:custom_cat_avatar_path, :string, default: "")
      add(:is_using_gravatar, :boolean, default: true)
      add(:gravatar_variant, :string, default: "default")

      timestamps()
    end
  end
end
