defmodule AgentMonitor.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    create table(:conversations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:workflow_id, references(:workflows, type: :binary_id, on_delete: :delete_all))
      add(:agent_id, :string)
      add(:role, :string)
      add(:content, :text)
      add(:metadata, :map, default: %{})
      add(:tokens, :integer)
      add(:is_summary, :boolean, default: false)
      add(:summary_of, {:array, :binary_id}, default: [])

      timestamps()
    end

    create(index(:conversations, [:workflow_id]))
    create(index(:conversations, [:agent_id]))
  end
end
