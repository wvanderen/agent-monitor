defmodule AgentMonitor.Repo.Migrations.CreateApprovalWhitelist do
  use Ecto.Migration

  def change do
    create table(:approval_whitelist, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:agent_id, :string)
      add(:incident_type, :string)
      add(:risk_level, :string)
      add(:action_pattern, :string)
      add(:expires_at, :utc_datetime)
      add(:created_by, :string)

      timestamps()
    end

    create(index(:approval_whitelist, [:agent_id]))
    create(index(:approval_whitelist, [:incident_type]))
    create(index(:approval_whitelist, [:risk_level]))
    create(index(:approval_whitelist, [:expires_at]))
  end
end
