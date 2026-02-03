defmodule AgentMonitor.MarketplaceAgent do
  @moduledoc """
  Schema for marketplace agents available for installation.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "marketplace_agents" do
    field(:name, :string)
    field(:description, :string)
    field(:author, :string)
    field(:version, :string)
    field(:capabilities, {:array, :string})
    field(:package_url, :string)
    field(:rating, :float)
    field(:downloads, :integer, default: 0)
    field(:is_installed, :boolean, default: false)
    field(:dependencies, {:array, :map}, default: [])
    field(:is_active, :boolean, default: true)

    has_many(:reviews, AgentMonitor.AgentReview, foreign_key: :agent_id)

    timestamps()
  end

  def changeset(marketplace_agent, attrs) do
    marketplace_agent
    |> cast(attrs, [
      :name,
      :description,
      :author,
      :version,
      :capabilities,
      :package_url,
      :rating,
      :downloads,
      :is_installed,
      :dependencies,
      :is_active
    ])
    |> validate_required([
      :name,
      :description,
      :author,
      :version,
      :capabilities
    ])
    |> validate_number(:rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_number(:downloads, greater_than_or_equal_to: 0)
  end

  def install_changeset(marketplace_agent) do
    change(marketplace_agent, is_installed: true)
  end

  def uninstall_changeset(marketplace_agent) do
    change(marketplace_agent, is_installed: false)
  end

  def update_rating_changeset(marketplace_agent, new_rating) do
    change(marketplace_agent, rating: new_rating)
  end

  def increment_downloads_changeset(marketplace_agent) do
    change(marketplace_agent, downloads: marketplace_agent.downloads + 1)
  end
end
