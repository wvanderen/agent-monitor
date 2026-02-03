defmodule AgentMonitor.Repo.Migrations.CreateIncidentRelations do
  use Ecto.Migration

  def change do
    create table(:incident_relations) do
      add(:incident_id, references(:incidents, type: :binary_id, on_delete: :delete_all))
      add(:related_incident_id, references(:incidents, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create(index(:incident_relations, [:incident_id]))
    create(index(:incident_relations, [:related_incident_id]))

    create(
      unique_index(:incident_relations, [:incident_id, :related_incident_id],
        name: :unique_incident_relations
      )
    )
  end
end
