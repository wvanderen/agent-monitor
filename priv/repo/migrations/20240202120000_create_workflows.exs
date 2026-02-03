defmodule AgentMonitor.Repo.Migrations.CreateWorkflows do
  use Ecto.Migration

  def change do
    create table(:workflows, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:status, :string, default: "pending")
      add(:current_step, :integer, default: 0)
      add(:steps, {:array, :map}, default: [])
      add(:context, :map, default: %{})
      add(:failed_step, :integer)
      add(:retry_count, :integer, default: 0)
      add(:max_retries, :integer, default: 3)

      timestamps()
    end

    create(index(:workflows, [:status]))
  end
end
