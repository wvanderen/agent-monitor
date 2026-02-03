defmodule AgentMonitor.Repo.Migrations.CreateAttachments do
  use Ecto.Migration

  def change do
    create table(:attachments, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:filename, :string)
      add(:content_type, :string)
      add(:file_path, :string)
      add(:file_size, :integer)
      add(:incident_id, references(:incidents, on_delete: :delete_all, type: :binary_id))

      timestamps()
    end

    create(index(:attachments, [:incident_id]))
  end
end
