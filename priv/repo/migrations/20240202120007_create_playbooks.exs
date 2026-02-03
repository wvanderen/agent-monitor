defmodule AgentMonitor.Repo.Migrations.CreatePlaybooks do
  use Ecto.Migration

  def change do
    create table(:playbooks, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:description, :text)
      add(:incident_type, :string)
      add(:service, :string)
      add(:variables, {:array, :map}, default: [])
      add(:steps, {:array, :map}, default: [])
      add(:version, :string, default: "1.0.0")
      add(:is_active, :boolean, default: true)
      add(:author, :string)

      timestamps()
    end

    create(index(:playbooks, [:incident_type]))
    create(index(:playbooks, [:service]))
    create(index(:playbooks, [:is_active]))
  end
end
