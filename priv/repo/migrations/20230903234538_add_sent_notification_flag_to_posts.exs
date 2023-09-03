defmodule Jarm.Repo.Migrations.AddSentNotificationFlagToPosts do
  use Ecto.Migration

  def change do
    alter table(:posts) do
      add(:notification_sent, :boolean, default: false)
    end
  end
end
