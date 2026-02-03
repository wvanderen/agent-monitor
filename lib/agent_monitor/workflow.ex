defmodule AgentMonitor.Workflow do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workflows" do
    field(:status, Ecto.Enum,
      values: [:pending, :in_progress, :completed, :failed],
      default: :pending
    )

    field(:current_step, :integer, default: 0)
    field(:steps, {:array, :map}, default: [])
    field(:context, :map, default: %{})
    field(:failed_step, :integer)
    field(:retry_count, :integer, default: 0)
    field(:max_retries, :integer, default: 3)
    field(:branch_status, :map, default: %{})
    field(:parallel_structure, {:array, :map}, default: [])
    field(:convergence_points, {:array, :integer}, default: [])
    field(:execution_mode, Ecto.Enum, values: [:sequential, :parallel, :auto], default: :auto)

    has_many(:conversations, AgentMonitor.Conversation)
    has_many(:context_versions, AgentMonitor.ContextVersion)
    has_many(:approvals, AgentMonitor.ApprovalRequest)
    belongs_to(:incident, AgentMonitor.Incident)
    belongs_to(:playbook, AgentMonitor.Playbook)

    timestamps()
  end

  def changeset(workflow, attrs) do
    workflow
    |> cast(attrs, [
      :status,
      :current_step,
      :steps,
      :context,
      :failed_step,
      :retry_count,
      :max_retries,
      :playbook_id,
      :incident_id,
      :branch_status,
      :parallel_structure,
      :convergence_points,
      :execution_mode
    ])
    |> validate_required([:incident_id])
    |> validate_number(:current_step, greater_than_or_equal_to: 0)
    |> validate_number(:retry_count, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:incident_id)
    |> foreign_key_constraint(:playbook_id)
  end

  def start_changeset(workflow) do
    workflow
    |> change(status: :in_progress, current_step: 0)
  end

  def complete_changeset(workflow) do
    workflow
    |> change(status: :completed)
  end

  def fail_changeset(workflow, step_index) do
    workflow
    |> change(status: :failed, failed_step: step_index)
  end

  def advance_step_changeset(workflow) do
    workflow
    |> change(current_step: workflow.current_step + 1)
  end

  def update_context_changeset(workflow, new_context) do
    workflow
    |> change(context: Map.merge(workflow.context, new_context))
  end

  def add_step_changeset(workflow, step_data) do
    workflow
    |> change(steps: workflow.steps ++ [step_data])
  end

  def retry_changeset(workflow) do
    workflow
    |> change(status: :in_progress, retry_count: workflow.retry_count + 1)
  end

  def can_retry?(workflow) do
    workflow.status == :failed && workflow.retry_count < workflow.max_retries
  end
end
