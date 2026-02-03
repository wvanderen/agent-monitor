defmodule AgentMonitor.Repo.Migrations.CreateContextVersions do
  use Ecto.Migration

  def change do
    create table(:context_versions, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:workflow_id, references(:workflows, type: :binary_id, on_delete: :delete_all))
      add(:step_number, :integer)
      add(:context_snapshot, :map)
      add(:agent_id, :string)

      timestamps()
    end

    create(unique_index(:context_versions, [:workflow_id, :step_number]))
    create(index(:context_versions, [:workflow_id]))
  end
end
