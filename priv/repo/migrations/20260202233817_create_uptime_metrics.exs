defmodule AgentMonitor.Repo.Migrations.CreateUptimeMetrics do
  use Ecto.Migration

  def change do
    create table(:uptime_metrics, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:timestamp, :utc_datetime, null: false)
      add(:service_id, :string, null: false)
      add(:status, :string, null: false)
      add(:response_time_ms, :integer)
      add(:incident_id, references(:incidents, on_delete: :nilify_all, type: :binary_id))

      timestamps()
    end

    create(index(:uptime_metrics, [:timestamp]))
    create(index(:uptime_metrics, [:service_id]))
    create(index(:uptime_metrics, [:incident_id]))
    create(index(:uptime_metrics, [:service_id, :timestamp]))
  end
end
