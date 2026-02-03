defmodule AgentMonitor.AgentReview do
  @moduledoc """
  Schema for user reviews of marketplace agents.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "agent_reviews" do
    belongs_to(:agent, AgentMonitor.MarketplaceAgent)

    field(:user_id, :string)
    field(:rating, :integer)
    field(:review_text, :string)

    timestamps()
  end

  def changeset(agent_review, attrs) do
    agent_review
    |> cast(attrs, [
      :agent_id,
      :user_id,
      :rating,
      :review_text
    ])
    |> validate_required([
      :agent_id,
      :user_id,
      :rating
    ])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> foreign_key_constraint(:agent_id)
  end
end
