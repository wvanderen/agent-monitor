defmodule AgentMonitor.ContextVersion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "context_versions" do
    field(:step_number, :integer)
    field(:context_snapshot, :map)
    field(:agent_id, :string)

    belongs_to(:workflow, AgentMonitor.Workflow)

    timestamps()
  end

  def changeset(context_version, attrs) do
    context_version
    |> cast(attrs, [:step_number, :context_snapshot, :agent_id, :workflow_id])
    |> validate_required([:workflow_id, :step_number, :context_snapshot])
    |> validate_number(:step_number, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:workflow_id)
    |> unique_constraint([:workflow_id, :step_number])
  end

  def create_snapshot(workflow_id, step_number, context, agent_id \\ nil) do
    %__MODULE__{}
    |> changeset(%{
      workflow_id: workflow_id,
      step_number: step_number,
      context_snapshot: context,
      agent_id: agent_id
    })
  end
end
