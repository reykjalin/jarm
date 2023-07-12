defmodule Jarm.Repo.Migrations.AddIsAdminFlagToAccounts do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_admin, :boolean, null: false, default: false
    end
  end
end
