defmodule AgentMonitor.ApprovalRequest do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "approval_requests" do
    field(:agent_id, :string)
    field(:action, :string)

    field(:status, Ecto.Enum,
      values: [:pending, :approved, :rejected, :expired],
      default: :pending
    )

    field(:context, :map, default: %{})
    field(:risk_level, Ecto.Enum, values: [:low, :medium, :high, :critical], default: :medium)
    field(:expires_at, :utc_datetime)
    field(:approved_by, :string)
    field(:approved_at, :utc_datetime)
    field(:rejection_reason, :string)
    field(:modifications, :map)

    belongs_to(:workflow, AgentMonitor.Workflow)

    timestamps()
  end

  def changeset(approval_request, attrs) do
    approval_request
    |> cast(attrs, [
      :agent_id,
      :action,
      :status,
      :context,
      :risk_level,
      :expires_at,
      :approved_by,
      :approved_at,
      :rejection_reason,
      :modifications,
      :workflow_id
    ])
    |> validate_required([:workflow_id, :agent_id, :action, :risk_level])
    |> foreign_key_constraint(:workflow_id)
  end

  def create_changeset(
        workflow_id,
        agent_id,
        action,
        context,
        risk_level,
        expires_in_minutes \\ 60
      ) do
    expires_at = DateTime.add(DateTime.utc_now(), expires_in_minutes * 60, :second)

    %__MODULE__{}
    |> changeset(%{
      workflow_id: workflow_id,
      agent_id: agent_id,
      action: action,
      context: context,
      risk_level: risk_level,
      expires_at: expires_at
    })
  end

  def approve_changeset(approval_request, approved_by, modifications \\ nil) do
    changeset(approval_request, %{
      status: :approved,
      approved_by: approved_by,
      approved_at: DateTime.utc_now(),
      modifications: modifications
    })
  end

  def reject_changeset(approval_request, approved_by, reason) do
    changeset(approval_request, %{
      status: :rejected,
      approved_by: approved_by,
      approved_at: DateTime.utc_now(),
      rejection_reason: reason
    })
  end

  def expire_changeset(approval_request) do
    changeset(approval_request, %{status: :expired})
  end

  def is_expired?(approval_request) do
    DateTime.compare(DateTime.utc_now(), approval_request.expires_at) != :lt
  end

  def is_pending?(approval_request) do
    approval_request.status == :pending && !is_expired?(approval_request)
  end
end
