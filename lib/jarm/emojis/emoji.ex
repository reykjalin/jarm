defmodule Jarm.Emojis.Emoji do
  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: true, source: :rowid}
  schema "emojis" do
    field :emoji, :string
    field :name, :string
    field :keywords, :string
    field :rank, :float, virtual: true

    timestamps()
  end
end
