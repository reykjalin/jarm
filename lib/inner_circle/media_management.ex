defmodule InnerCircle.MediaManagement do
  import Ecto.Query, warn: false
  alias InnerCircle.Repo

  use Nebulex.Caching

  alias InnerCircle.Accounts.User
  alias InnerCircle.Timeline.Media

  def list_media_for_user(%User{id: id}) do
    from(m in Media, where: m.user_id == ^id, order_by: [desc: :inserted_at])
    |> Repo.all()
  end
end
