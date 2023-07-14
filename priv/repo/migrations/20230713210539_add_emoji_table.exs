defmodule Jarm.Repo.Migrations.AddEmojiTable do
  use Ecto.Migration

  def change do
    execute(
      """
      CREATE VIRTUAL TABLE emojis USING fts5(
        updated_at UNINDEXED,
        inserted_at UNINDEXED,
        emoji UNINDEXED,
        name,
        keywords,
        tokenize="trigram"
      );
      """,
      """
      DROP TABLE emojis;
      """
    )
  end

end
