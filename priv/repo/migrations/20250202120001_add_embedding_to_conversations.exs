defmodule AgentMonitor.Repo.Migrations.AddEmbeddingToConversations do
  use Ecto.Migration

  def change do
    alter table(:conversations) do
      add(:embedding, {:array, :float})
      add(:topic, :string)
    end
  end
end
