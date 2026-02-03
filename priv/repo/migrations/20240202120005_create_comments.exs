defmodule AgentMonitor.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:content, :text)
      add(:author, :string)
      add(:incident_id, references(:incidents, type: :binary_id, on_delete: :delete_all))

      timestamps()
    end

    create(index(:comments, [:incident_id]))
  end
end
