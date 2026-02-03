defmodule AgentMonitor.Repo.Migrations.FixWorkflowIncidentId do
  use Ecto.Migration

  def change do
    alter table(:workflows) do
      remove(:incident_id, :string)
      remove(:incident_id_ref, references(:incidents, type: :binary_id))
    end

    drop_if_exists(index(:workflows, [:incident_id]))
    drop_if_exists(index(:workflows, [:incident_id_ref]))

    # Add proper foreign key via belongs_to relationship
    alter table(:workflows) do
      add(:incident_id, references(:incidents, type: :binary_id, on_delete: :nilify_all))
    end

    create(index(:workflows, [:incident_id]))
  end
end
