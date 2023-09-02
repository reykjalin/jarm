defmodule Jarm.Repo.Migrations.AddDimensionsToMedia do
  use Ecto.Migration

  def change do
    alter table(:media) do
      add(:width, :integer, default: 0)
      add(:height, :integer, default: 0)
    end
  end
end
