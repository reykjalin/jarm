defmodule Jarm.Reactions do
  import Ecto.Query, warn: false
  alias Jarm.Repo

  alias Jarm.Reactions.{Emoji, PostReaction}

  def subscribe() do
    Phoenix.PubSub.subscribe(Jarm.PubSub, "post_reactions")
  end

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

  def toggle_reaction(post_id, emoji_id, user_id) do
    case get_reaction(post_id, emoji_id, user_id) do
      nil ->
        add_reaction(post_id, emoji_id, user_id)
        |> broadcast(:reaction_added)

      reaction ->
        IO.inspect(reaction, label: "reaction to delete")

        delete_reaction(reaction)
        |> broadcast(:reaction_deleted)
    end
  end

  defp add_reaction(post_id, emoji_id, user_id) do
    PostReaction.changeset(%PostReaction{post_id: post_id, emoji_id: emoji_id, user_id: user_id})
    |> Repo.insert()
  end

  defp delete_reaction(%PostReaction{} = reaction) do
    Repo.delete(reaction)
  end

  defp get_reaction(post_id, emoji_id, user_id) do
    Repo.get_by(PostReaction, post_id: post_id, emoji_id: emoji_id, user_id: user_id)
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, %PostReaction{} = reaction}, event) do
    Phoenix.PubSub.broadcast(Jarm.PubSub, "post_reactions", {event, reaction})
    {:ok, reaction}
  end
end
