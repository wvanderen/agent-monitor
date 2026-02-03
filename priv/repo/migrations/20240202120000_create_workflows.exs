defmodule AgentMonitor.Repo.Migrations.CreateWorkflows do
  use Ecto.Migration

  def change do
    create table(:workflows, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:incident_id, :string)
      add(:status, :string, default: "pending")
      add(:current_step, :integer, default: 0)
      add(:steps, {:array, :map}, default: [])
      add(:context, :map, default: %{})
      add(:failed_step, :integer)
      add(:retry_count, :integer, default: 0)
      add(:max_retries, :integer, default: 3)
      add(:playbook_id, references(:playbooks, type: :binary_id), null: true)
      add(:incident_id_ref, references(:incidents, type: :binary_id), null: true)

      timestamps()
    end

    create(index(:workflows, [:incident_id]))
    create(index(:workflows, [:status]))
    create(index(:workflows, [:playbook_id]))
    create(index(:workflows, [:incident_id_ref]))
  end
end
