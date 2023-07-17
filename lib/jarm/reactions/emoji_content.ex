defmodule Jarm.Reactions.EmojiContent do
  @moduledoc """
  This module mirrors `Jarm.Reactions.Emoji` exactly, but is necessary for foreign key constraints.
  FST5 tables in SQLite don't have IDs, relying instead on the row number, so there's no easy way
  to add foreign key relations. FST5 tables do, however, create a '%_content' table that does have
  IDs that seem to correspond to the main table rowid for the same entry.

  More described in https://www.sqlite.org/fts5.html#the_table_contents_content_table_ .
  """
  use Ecto.Schema

  schema "emojis_content" do
    field :emoji, :string, source: :c2
    field :name, :string, source: :c3
    field :keywords, :string, source: :c4

    timestamps(
      inserted_at: :c1,
      updated_at: :c0
    )
  end
end
