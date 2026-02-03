defmodule AgentMonitor.Repo.Migrations.AddServiceIdToIncidents do
  use Ecto.Migration

  def change do
    alter table(:incidents) do
      add(:service_id, :string)
    end

    create(index(:incidents, [:service_id]))
  end
end
