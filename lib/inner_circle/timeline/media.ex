defmodule InnerCircle.Timeline.Media do
  use Ecto.Schema
  import Ecto.Changeset

  schema "media" do
    field :url, :string
    field :path_to_original, :string
    field :mime_type, :string
    field :uuid, Ecto.UUID
    belongs_to :user, InnerCircle.Accounts.User
    belongs_to :post, InnerCircle.Timeline.Post

    timestamps()
  end

  @doc false
  def changeset(media, attrs) do
    media
    |> cast(attrs, [:url, :path_to_original, :uuid, :mime_type])
    |> validate_required([:url, :path_to_original, :uuid, :mime_type])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
  end
end
