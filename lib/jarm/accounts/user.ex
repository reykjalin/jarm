defmodule Jarm.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Inspect, except: [:password]}
  schema "users" do
    field :display_name, :string
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :is_admin, :boolean, default: false

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:display_name, :email, :password])
    |> validate_display_name()
    |> validate_email()
    |> validate_password(opts)
  end

  defp validate_display_name(changeset) do
    changeset
    |> validate_required([:display_name])
    |> validate_length(:display_name, max: 254)
    |> unsafe_validate_unique(:display_name, Jarm.Repo)
    |> unique_constraint(:display_name)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Jarm.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 80)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the display name.

  It requires the display name to change otherwise an error is added.
  """
  def display_name_changeset(user, attrs) do
    user
    |> cast(attrs, [:display_name])
    |> validate_display_name()
    |> case do
      %{changes: %{display_name: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :display_name, "did not change")
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  A user changeset for granting elevated privileges.
  """
  def grant_administrator_privileges_changeset(user, attrs) do
    user
    |> cast(attrs, [:is_admin])
    |> case do
      %{changes: %{is_admin: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :is_admin, "did not change")
    end
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Jarm.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  @doc """
  Returns true when user has admin privileges, false otherwise.
  """
  def has_admin_privileges(%Jarm.Accounts.User{is_admin: is_admin}), do: is_admin
  def has_admin_privileges(_), do: false
end

defimpl Canada.Can, for: Jarm.Accounts.User do
  alias Jarm.Accounts.User
  alias Jarm.Timeline.Post

  def can?(%User{is_admin: is_admin}, action, %Post{}), do: is_admin

  def can?(%User{id: user_id}, action, %Post{user_id: user_id})
      when action in [:edit, :delete],
      do: true

  def can?(%User{}, action, %Post{})
      when action in [:edit, :delete],
      do: false

  def can?(%User{}, :create, Post), do: true
  def can?(%User{}, :create, %Post{}), do: true
  def can?(%User{}, :read, Post), do: true
  def can?(%User{}, :read, %Post{}), do: true
end
