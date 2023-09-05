defmodule Jarm.Accounts.UserConfiguration do
  use Ecto.Schema

  schema "user_configuration" do
    field :avatar, :string, default: ""
    field :email_cat_avatar_path, :string, default: ""
    field :display_name_cat_avatar_path, :string, default: ""
    field :custom_cat_avatar_path, :string, default: ""
    field :is_using_gravatar, :boolean, default: true
    field :gravatar_variant, :string, default: "default"

    belongs_to :user, Jarm.Accounts.User

    timestamps()
  end
end
