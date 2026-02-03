defmodule AgentMonitor.UptimeMetric do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "uptime_metrics" do
    field(:timestamp, :utc_datetime)
    field(:service_id, :string)
    field(:status, Ecto.Enum, values: [:up, :down, :degraded])
    field(:response_time_ms, :integer)

    belongs_to(:incident, AgentMonitor.Incident)

    timestamps()
  end

  def changeset(uptime_metric, attrs) do
    uptime_metric
    |> cast(attrs, [
      :timestamp,
      :service_id,
      :status,
      :response_time_ms,
      :incident_id
    ])
    |> validate_required([
      :timestamp,
      :service_id,
      :status
    ])
    |> validate_number(:response_time_ms, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:incident_id)
  end

  def create_metric(service_id, status, response_time_ms \\ nil, incident_id \\ nil) do
    attrs = %{
      timestamp: DateTime.utc_now(),
      service_id: service_id,
      status: status,
      response_time_ms: response_time_ms
    }

    attrs =
      if incident_id do
        Map.put(attrs, :incident_id, incident_id)
      else
        attrs
      end

    %__MODULE__{}
    |> changeset(attrs)
  end

  def is_up?(metric), do: metric.status == :up
  def is_down?(metric), do: metric.status == :down
  def is_degraded?(metric), do: metric.status == :degraded
end
