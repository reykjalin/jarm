defmodule Jarm.Repo.Migrations.AddSentNotificationFlagToComments do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      add(:notification_sent, :boolean, default: false)
    end
  end
end
