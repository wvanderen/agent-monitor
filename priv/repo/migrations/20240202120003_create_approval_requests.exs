defmodule AgentMonitor.Repo.Migrations.CreateApprovalRequests do
  use Ecto.Migration

  def change do
    create table(:approval_requests, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:workflow_id, references(:workflows, type: :binary_id, on_delete: :delete_all))
      add(:agent_id, :string)
      add(:action, :string)
      add(:status, :string, default: "pending")
      add(:context, :map, default: %{})
      add(:risk_level, :string, default: "medium")
      add(:expires_at, :utc_datetime)
      add(:approved_by, :string)
      add(:approved_at, :utc_datetime)
      add(:rejection_reason, :string)
      add(:modifications, :map)

      timestamps()
    end

    create(index(:approval_requests, [:workflow_id]))
    create(index(:approval_requests, [:status]))
  end
end
