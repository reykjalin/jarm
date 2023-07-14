defmodule Jarm.Emojis do
  import Ecto.Query, warn: false
  alias Jarm.Repo

  alias Jarm.Emojis.Emoji

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

end
