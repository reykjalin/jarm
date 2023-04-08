defmodule InnerCircle.Repo.Migrations.AddJarmTranslations do
  use Ecto.Migration

  def up do
    alter table("posts") do
      add :locale, :string, default: "en"
    end

    create table("translations") do
      add :user_id, references(:users, on_delete: :delete_all)
      add :post_id, references(:posts, on_delete: :delete_all)
      add :locale, :string
      add :body, :string

      timestamps()
    end
  end

  def down do
    alter table("posts") do
      remove :locale
    end

    drop_if_exists table("translations")
  end
end
