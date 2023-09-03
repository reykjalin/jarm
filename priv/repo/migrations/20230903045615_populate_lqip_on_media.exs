defmodule Jarm.Repo.Migrations.PopulateLqipOnMedia do
  use Ecto.Migration

  alias Jarm.Repo

  def up do
    import Ecto.Query, only: [from: 2]

    from("media", select: [:id, :mime_type, :path_to_compressed, :path_to_thumbnail])
    |> Repo.all()
    |> Enum.map(fn m ->
      path_to_image =
        if m.mime_type |> String.starts_with?("image") do
          m.path_to_compressed
        else
          m.path_to_thumbnail
        end

      data_uri =
        case Sqip.generate_svg_data_uri(path_to_image) do
          {:ok, result} ->
            File.rm!(result.output_file)
            result.data_uri

          _ ->
            ""
        end

      from(me in "media", where: me.id == ^m.id)
      |> Repo.update_all(set: [lqip: data_uri])
    end)
  end

  def down do
    # Nothing to do.
  end
end
