defmodule AgentMonitor.Repo.Migrations.AddParallelWorkflowFields do
  use Ecto.Migration

  def change do
    alter table(:workflows) do
      add(:branch_status, :map, default: %{})
      add(:parallel_structure, {:array, :map}, default: [])
      add(:convergence_points, {:array, :integer}, default: [])
      add(:execution_mode, Ecto.Enum, values: [:sequential, :parallel, :auto], default: :auto)
    end
  end
end
