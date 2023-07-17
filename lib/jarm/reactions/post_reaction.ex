defmodule Jarm.Reactions.PostReaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_reactions" do
    belongs_to :user, Jarm.Accounts.User
    belongs_to :post, Jarm.Timeline.Post
    belongs_to :emoji, Jarm.Reactions.EmojiContent

    timestamps()
  end

  def changeset(reaction, attrs \\ %{}) do
    reaction
    |> cast(attrs, [])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
    |> foreign_key_constraint(:emoji_id)
  end
end
