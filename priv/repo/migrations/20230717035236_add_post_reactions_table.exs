defmodule Jarm.Repo.Migrations.AddPostReactionsTable do
  use Ecto.Migration

  def change do
    create table("post_reactions") do
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:post_id, references(:posts, on_delete: :delete_all))
      add(:emoji_id, references(:emojis_content, on_delete: :delete_all))

      timestamps()
    end
  end
end
