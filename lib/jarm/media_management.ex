defmodule Jarm.MediaManagement do
  import Ecto.Query, warn: false
  alias Jarm.Repo

  use Nebulex.Caching

  alias Jarm.Accounts.User
  alias Jarm.Timeline.Media

  def list_media_for_user(%User{id: id}) do
    from(m in Media, where: m.user_id == ^id, order_by: [desc: :inserted_at])
    |> Repo.all()
  end
end
