defmodule InnerCircle.Repo.Migrations.RemoveUrlFromMedia do
  use Ecto.Migration

  alias InnerCircle.Repo

  def up do
    alter table(:media) do
      remove :url
    end
  end

  def down do
    alter table(:media) do
      add :url, :string
    end

    flush()

    import Ecto.Query, only: [from: 2]

    from("media", select: [:id, :mime_type, :uuid])
    |> Repo.all()
    |> Enum.map(fn m ->
      ext = MIME.extensions(m.mime_type) |> hd
      url = "/media/#{m.uuid}.#{ext}"

      from(me in Media, where: me.id == ^m.id)
      |> Repo.update_all(set: [url: url])
    end)
  end
end
