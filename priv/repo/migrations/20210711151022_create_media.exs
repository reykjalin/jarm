defmodule Jarm.Repo.Migrations.CreateMedia do
  use Ecto.Migration

  def change do
    create table(:media) do
      add :url, :string
      add :path_to_original, :string
      add :mime_type, :string
      add :uuid, :binary_id
      add :user_id, references(:users, on_delete: :delete_all)
      add :post_id, references(:posts, on_delete: :delete_all)

      timestamps()
    end
  end
end
