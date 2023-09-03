defmodule Jarm.Repo.Migrations.AddLqipToMedia do
  use Ecto.Migration

  def change do
    alter table(:media) do
      add(:lqip, :string, default: "")
    end
  end
end
