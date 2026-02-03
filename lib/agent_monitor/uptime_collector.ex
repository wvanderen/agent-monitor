defmodule AgentMonitor.UptimeCollector do
  @moduledoc """
  Collects uptime metrics for monitored services.
  Runs periodically to record service status.
  """

  use GenServer
  require Logger

  alias AgentMonitor.UptimeMetric
  alias AgentMonitor.Repo

  @check_interval :timer.minutes(5)

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def collect_metric(service_id, status, response_time_ms \\ nil, incident_id \\ nil) do
    GenServer.cast(
      __MODULE__,
      {:collect_metric, service_id, status, response_time_ms, incident_id}
    )
  end

  def get_uptime_percentage(service_id, time_range \\ nil) do
    GenServer.call(__MODULE__, {:get_uptime_percentage, service_id, time_range})
  end

  def get_metrics(service_id, time_range \\ nil) do
    GenServer.call(__MODULE__, {:get_metrics, service_id, time_range})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    schedule_next_check()

    Logger.info("Starting UptimeCollector")

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:collect_metric, service_id, status, response_time_ms, incident_id}, state) do
    metric = UptimeMetric.create_metric(service_id, status, response_time_ms, incident_id)

    case Repo.insert(metric) do
      {:ok, _inserted} ->
        :ok

      {:error, changeset} ->
        Logger.error("Failed to insert uptime metric: #{inspect(changeset.errors)}")
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:get_uptime_percentage, service_id, time_range}, _from, state) do
    percentage = calculate_uptime_percentage(service_id, time_range)
    {:reply, percentage, state}
  end

  @impl true
  def handle_call({:get_metrics, service_id, time_range}, _from, state) do
    metrics = fetch_metrics(service_id, time_range)
    {:reply, metrics, state}
  end

  @impl true
  def handle_info(:check_services, state) do
    check_all_services()
    schedule_next_check()

    {:noreply, state}
  end

  # Private Functions

  defp schedule_next_check do
    Process.send_after(self(), :check_services, @check_interval)
  end

  defp check_all_services do
    services = get_monitored_services()

    Enum.each(services, fn service_id ->
      check_service(service_id)
    end)
  end

  defp get_monitored_services do
    import Ecto.Query

    query =
      from(i in AgentMonitor.Incident,
        select: i.service_id,
        distinct: true,
        where: i.status in [:open, :in_progress],
        order_by: [asc: i.service_id]
      )

    query
    |> Repo.all()
    |> Enum.filter(fn service_id -> service_id != nil and service_id != "" end)
  end

  defp check_service(service_id) do
    Logger.debug("Checking service: #{service_id}")

    start_time = System.monotonic_time(:millisecond)

    case HTTPoison.get(service_id, [], timeout: 10_000) do
      {:ok, %{status_code: _code}} when _code >= 200 and _code < 300 ->
        _end_time = System.monotonic_time(:millisecond)
        response_time = _end_time - start_time

        collect_metric(service_id, :up, response_time)

      {:ok, %{status_code: code}} when code >= 400 and code < 500 ->
        collect_metric(service_id, :degraded)

      {:ok, %{status_code: code}} ->
        collect_metric(service_id, :down)

      {:error, %{reason: :timeout}} ->
        collect_metric(service_id, :down)

      {:error, %{reason: reason}} ->
        Logger.warning("Service check failed: #{inspect(reason)}")
        collect_metric(service_id, :down)
    end
  end

  defp calculate_uptime_percentage(service_id, time_range) do
    metrics = fetch_metrics(service_id, time_range)

    if Enum.empty?(metrics) do
      100.0
    else
      up_count =
        metrics
        |> Enum.count(&UptimeMetric.is_up?/1)

      total_count = length(metrics)

      (up_count / total_count * 100)
      |> Float.round(2)
    end
  end

  defp fetch_metrics(_service_id, _time_range \\ nil) do
    import Ecto.Query

    from(u in UptimeMetric,
      order_by: [desc: u.timestamp],
      limit: 100
    )
    |> Repo.all()
  end
end
