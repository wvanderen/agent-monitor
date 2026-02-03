defmodule AgentMonitor.Repo.Migrations.CreateAgentReviews do
  use Ecto.Migration

  def change do
    create table(:agent_reviews, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:agent_id, references(:marketplace_agents, type: :binary_id, on_delete: :delete_all))
      add(:user_id, :string)
      add(:rating, :integer)
      add(:review_text, :text)

      timestamps()
    end

    create(index(:agent_reviews, [:agent_id]))
    create(index(:agent_reviews, [:user_id]))
    create(index(:agent_reviews, [:rating]))
  end
end
