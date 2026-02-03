defmodule AgentMonitor.Repo.Migrations.CreateIncidents do
  use Ecto.Migration

  def change do
    create table(:incidents, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:title, :string)
      add(:description, :text)
      add(:status, :string, default: "open")
      add(:severity, :string, default: "P3")
      add(:assigned_to, :string)
      add(:detected_at, :utc_datetime)
      add(:resolved_at, :utc_datetime)
      add(:closed_at, :utc_datetime)

      timestamps()
    end

    create(index(:incidents, [:status]))
    create(index(:incidents, [:severity]))
    create(index(:incidents, [:assigned_to]))
  end
end
