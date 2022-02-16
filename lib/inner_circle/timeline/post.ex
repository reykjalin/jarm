defmodule InnerCircle.Timeline.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string
    has_many :media, InnerCircle.Timeline.Media
    has_many :comments, InnerCircle.Timeline.Comment
    belongs_to :user, InnerCircle.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:body])
    |> validate_required([:body])
    |> validate_length(:body, min: 2)
  end
end
