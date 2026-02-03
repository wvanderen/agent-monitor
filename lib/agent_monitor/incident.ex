defmodule AgentMonitor.Incident do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "incidents" do
    field(:title, :string)
    field(:description, :string)
    field(:service_id, :string)

    field(:status, Ecto.Enum,
      values: [:open, :in_progress, :resolved, :closed, :reopened],
      default: :open
    )

    field(:severity, Ecto.Enum, values: [:P1, :P2, :P3, :P4], default: :P3)
    field(:assigned_to, :string)
    field(:detected_at, :utc_datetime)
    field(:resolved_at, :utc_datetime)
    field(:closed_at, :utc_datetime)

    has_many(:workflows, AgentMonitor.Workflow)
    has_many(:comments, AgentMonitor.Comment)
    has_many(:uptime_metrics, AgentMonitor.UptimeMetric)

    many_to_many(:related_incidents, AgentMonitor.Incident,
      join_through: "incident_relations",
      join_keys: [incident_id: :id, related_incident_id: :id]
    )

    belongs_to(:playbook, AgentMonitor.Playbook)

    timestamps()
  end

  def changeset(incident, attrs) do
    incident
    |> cast(attrs, [
      :title,
      :description,
      :service_id,
      :status,
      :severity,
      :assigned_to,
      :detected_at,
      :resolved_at,
      :closed_at,
      :playbook_id
    ])
    |> validate_required([:title, :status, :severity])
    |> foreign_key_constraint(:playbook_id)
  end

  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> change(detected_at: DateTime.utc_now())
  end

  def assign_changeset(incident, assigned_to) do
    change(incident, assigned_to: assigned_to)
  end

  def resolve_changeset(incident) do
    change(incident, status: :resolved, resolved_at: DateTime.utc_now())
  end

  def close_changeset(incident) do
    resolved_at =
      if is_nil(incident.resolved_at), do: DateTime.utc_now(), else: incident.resolved_at

    change(incident, status: :closed, closed_at: DateTime.utc_now(), resolved_at: resolved_at)
  end

  def reopen_changeset(incident) do
    change(incident, status: :reopened)
  end

  def update_status_changeset(incident, new_status) do
    change(incident, status: new_status)
  end

  def severity_order(severity) do
    case severity do
      :P1 -> 0
      :P2 -> 1
      :P3 -> 2
      :P4 -> 3
      _ -> 99
    end
  end

  def is_closed?(incident) do
    incident.status == :closed
  end

  def is_resolved?(incident) do
    incident.status in [:resolved, :closed]
  end

  def can_transition_to?(incident, new_status) do
    valid_transitions(incident.status)
    |> Enum.member?(new_status)
  end

  defp valid_transitions(:open), do: [:in_progress, :closed]
  defp valid_transitions(:in_progress), do: [:resolved, :reopened, :closed]
  defp valid_transitions(:resolved), do: [:closed, :reopened]
  defp valid_transitions(:closed), do: [:reopened]
  defp valid_transitions(:reopened), do: [:open, :in_progress]
end
