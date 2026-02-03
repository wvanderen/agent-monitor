defmodule AgentMonitor.Repo.Migrations.FixWorkflowIncidentId do
  use Ecto.Migration

  def change do
    # Add incident_id foreign key to workflows
    alter table(:workflows) do
      add(:incident_id, references(:incidents, type: :binary_id, on_delete: :nilify_all))
    end

    # Add playbook_id foreign key to workflows
    alter table(:workflows) do
      add(:playbook_id, references(:playbooks, type: :binary_id), null: true)
    end

    # Add playbook_id foreign key to incidents
    alter table(:incidents) do
      add(:playbook_id, references(:playbooks, type: :binary_id), null: true)
    end

    create(index(:workflows, [:incident_id]))
    create(index(:workflows, [:playbook_id]))
    create(index(:incidents, [:playbook_id]))
  end
end
