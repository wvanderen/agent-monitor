defmodule AgentMonitor.Repo.Migrations.CreateMarketplaceAgents do
  use Ecto.Migration

  def change do
    create table(:marketplace_agents, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string)
      add(:description, :text)
      add(:author, :string)
      add(:version, :string)
      add(:capabilities, {:array, :string})
      add(:package_url, :string)
      add(:rating, :float)
      add(:downloads, :integer, default: 0)
      add(:is_installed, :boolean, default: false)
      add(:dependencies, {:array, :map}, default: [])
      add(:is_active, :boolean, default: true)

      timestamps()
    end

    create(index(:marketplace_agents, [:is_active]))
    create(index(:marketplace_agents, [:is_installed]))
    create(index(:marketplace_agents, [:rating]))
  end
end
