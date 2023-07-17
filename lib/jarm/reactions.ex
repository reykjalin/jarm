defmodule Jarm.Reactions do
  import Ecto.Query, warn: false
  alias Jarm.Repo

  alias Jarm.Reactions.{Emoji, PostReaction}

  def search_emojis(q) do
    from(
      e in Emoji,
      select: [:emoji, :name, :keywords, :rank, :id],
      where: fragment("emojis MATCH ?", ^q),
      order_by: [asc: :rank]
    )
    |> Repo.all()
  end

  def all_emojis() do
    from(e in Emoji) |> Repo.all()
  end

  def add_reaction(post_id, emoji_id, user_id) do
    PostReaction.changeset(%PostReaction{post_id: post_id, emoji_id: emoji_id, user_id: user_id})
    |> Repo.insert()
  end
end
