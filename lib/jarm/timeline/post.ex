defmodule Jarm.Timeline.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string
    field :locale, :string
    field :notification_sent, :boolean, default: false
    has_many :media, Jarm.Timeline.Media
    has_many :comments, Jarm.Timeline.Comment
    has_many :translations, Jarm.Timeline.Translation
    has_many :reactions, Jarm.Reactions.PostReaction
    belongs_to :user, Jarm.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:body, :locale])
    |> validate_required([:body])
    |> validate_length(:body, min: 2)
  end
end
