defmodule Jarm.Timeline.Translation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "translations" do
    field :body, :string
    field :locale, :string
    belongs_to :user, Jarm.Accounts.User
    belongs_to :post, Jarm.Timeline.Post

    timestamps()
  end

  @doc false
  def changeset(media, attrs) do
    media
    |> cast(attrs, [
      :body,
      :locale
    ])
    |> validate_required([
      :body,
      :locale
    ])
    |> validate_length(:body, min: 2)
    |> validate_inclusion(:locale, ["en", "is", "fil"])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:post_id)
  end
end
