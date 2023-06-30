defmodule Jarm.Timeline.Media do
  use Ecto.Schema
  import Ecto.Changeset

  schema "media" do
    field(:path_to_original, :string)
    field(:path_to_compressed, :string)
    field(:path_to_thumbnail, :string)
    field(:mime_type, :string)
    field(:uuid, Ecto.UUID)
    field(:blurhash, :string)
    belongs_to(:user, Jarm.Accounts.User)
    belongs_to(:post, Jarm.Timeline.Post)

    timestamps()
  end

  @doc false
  def changeset(media, attrs) do
    media
    |> cast(attrs, [
      :path_to_original,
      :path_to_compressed,
      :path_to_thumbnail,
      :uuid,
      :mime_type,
      :blurhash
    ])
    |> validate_required([
      :path_to_original,
      :path_to_compressed,
      :path_to_thumbnail,
      :uuid,
      :mime_type,
      :blurhash
    ])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
  end
end
