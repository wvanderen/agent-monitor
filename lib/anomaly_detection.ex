defmodule AnomalyDetection do
  @moduledoc """
  Anomaly Detection module using ETS tables for baseline metrics.

  Stores historical metrics, calculates baselines, and detects anomalies
  using sliding window analysis.
  """

  use GenServer
  require Logger

  @ets_table :anomaly_metrics
  @baseline_window 100
  @anomaly_window 10
  @threshold_multiplier 2.5

  defmodule Metric do
    @moduledoc """
    Structure for individual metric samples.
    """
    defstruct [
      :url,
      :timestamp,
      :status,
      :duration_ms,
      :body_size,
      :status_code
    ]

    @doc """
    Create a new metric from endpoint check result.
    """
    def new(url, result) do
      %__MODULE__{
        url: url,
        timestamp: DateTime.utc_now(),
        status: Map.get(result, :status, :unknown),
        duration_ms: Map.get(result, :duration_ms, 0),
        body_size: Map.get(result, :body_size, 0),
        status_code: Map.get(result, :code)
      }
    end
  end

  defmodule Baseline do
    @moduledoc """
    Baseline metrics for an endpoint.
    """
    defstruct [
      :url,
      :avg_duration_ms,
      :std_duration_ms,
      :success_rate,
      :sample_count,
      :last_updated
    ]

    @doc """
    Calculate baseline from a list of metrics.
    """
    def from_metrics(url, metrics) when is_list(metrics) and length(metrics) > 0 do
      durations = Enum.map(metrics, & &1.duration_ms)
      successes = Enum.count(metrics, &(&1.status == :ok))
      count = length(metrics)

      avg = Enum.sum(durations) / count

      variance =
        Enum.reduce(durations, 0, fn d, acc ->
          acc + :math.pow(d - avg, 2)
        end) / count

      std = :math.sqrt(variance)

      %__MODULE__{
        url: url,
        avg_duration_ms: Float.round(avg, 2),
        std_duration_ms: Float.round(std, 2),
        success_rate: Float.round(successes / count * 100, 2),
        sample_count: count,
        last_updated: DateTime.utc_now()
      }
    end

    def from_metrics(_url, _metrics) do
      nil
    end
  end

  defmodule AnomalyReport do
    @moduledoc """
    Report of detected anomaly.
    """
    defstruct [
      :url,
      :anomaly_type,
      :severity,
      :current_value,
      :baseline_value,
      :deviation,
      :description,
      :timestamp
    ]
  end

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Record a new metric sample.
  """
  def record_metric(url, result) do
    metric = Metric.new(url, result)
    GenServer.cast(__MODULE__, {:record_metric, metric})
  end

  @doc """
  Get baseline for an endpoint.
  """
  def get_baseline(url) do
    GenServer.call(__MODULE__, {:get_baseline, url})
  end

  @doc """
  Check if current metric is anomalous.
  """
  def check_anomaly(url, result) do
    metric = Metric.new(url, result)
    GenServer.call(__MODULE__, {:check_anomaly, metric})
  end

  @doc """
  Get all metrics for an endpoint.
  """
  def get_metrics(url, limit \\ 100) do
    GenServer.call(__MODULE__, {:get_metrics, url, limit})
  end

  @doc """
  Reset metrics for an endpoint.
  """
  def reset_metrics(url) do
    GenServer.cast(__MODULE__, {:reset_metrics, url})
  end

  @doc """
  Get statistics about the anomaly detection system.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    Logger.info("Starting Anomaly Detection Service")

    table = :ets.new(@ets_table, [:named_table, :set, :private, read_concurrency: true])

    state = %{
      table: table,
      baseline_window: @baseline_window,
      anomaly_window: @anomaly_window,
      threshold_multiplier: @threshold_multiplier
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:record_metric, metric}, state) do
    do_record_metric(metric, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:reset_metrics, url}, state) do
    :ets.delete(state.table, url)
    Logger.info("Reset metrics for endpoint: #{url}")
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_baseline, url}, _from, state) do
    baseline = do_get_baseline(url, state)
    {:reply, baseline, state}
  end

  @impl true
  def handle_call({:check_anomaly, metric}, _from, state) do
    anomaly = do_check_anomaly(metric, state)
    {:reply, anomaly, state}
  end

  @impl true
  def handle_call({:get_metrics, url, limit}, _from, state) do
    metrics = do_get_metrics(url, limit, state)
    {:reply, metrics, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = do_get_stats(state)
    {:reply, stats, state}
  end

  # Private Functions

  defp do_record_metric(metric, state) do
    case :ets.lookup(state.table, metric.url) do
      [{url, metrics}] when url == metric.url ->
        updated = [metric | Enum.take(metrics, state.baseline_window - 1)]
        :ets.insert(state.table, {metric.url, updated})

      [] ->
        :ets.insert(state.table, {metric.url, [metric]})
    end
  end

  defp do_get_baseline(url, state) do
    case :ets.lookup(state.table, url) do
      [{^url, metrics}] when is_list(metrics) and length(metrics) > 10 ->
        Baseline.from_metrics(url, metrics)

      _ ->
        nil
    end
  end

  defp do_check_anomaly(metric, state) do
    case do_get_baseline(metric.url, state) do
      nil ->
        {:ok, nil}

      baseline ->
        metrics = do_get_metrics(metric.url, state.anomaly_window, state)

        {_severity, report} =
          check_duration_anomaly(metric, baseline, metrics, state.threshold_multiplier)
          |> check_status_anomaly(metric, baseline, metrics)

        {:ok, report}
    end
  end

  defp check_duration_anomaly(metric, baseline, _metrics, threshold) do
    deviation = metric.duration_ms - baseline.avg_duration_ms
    std_dev = baseline.std_duration_ms
    threshold_value = std_dev * threshold

    severity =
      cond do
        std_dev == 0 ->
          :info

        abs(deviation) > threshold_value ->
          if deviation > 0, do: :error, else: :info

        abs(deviation) > threshold_value * 0.5 ->
          if deviation > 0, do: :warning, else: :info

        true ->
          :ok
      end

    {severity,
     %AnomalyReport{
       url: metric.url,
       anomaly_type: :duration,
       severity: severity,
       current_value: metric.duration_ms,
       baseline_value: baseline.avg_duration_ms,
       deviation: Float.round(deviation / baseline.avg_duration_ms * 100, 2),
       description: describe_duration_anomaly(metric, baseline, deviation, threshold_value),
       timestamp: metric.timestamp
     }}
  end

  defp check_status_anomaly({severity, report}, _metric, baseline, metrics) do
    recent_failures = Enum.count(metrics, &(&1.status == :error))

    anomaly_type =
      cond do
        severity == :ok and recent_failures > length(metrics) * 0.5 ->
          :status

        true ->
          :none
      end

    if anomaly_type == :status do
      new_severity = :error

      new_report = %{
        report
        | anomaly_type: :status,
          severity: new_severity,
          current_value: recent_failures,
          baseline_value: Float.round((1 - baseline.success_rate / 100) * length(metrics), 1),
          deviation: Float.round(recent_failures / length(metrics) * 100, 2),
          description:
            "High failure rate detected: #{recent_failures}/#{length(metrics)} recent checks failed"
      }

      {:error, new_report}
    else
      {severity, report}
    end
  end

  defp describe_duration_anomaly(_metric, baseline, deviation, threshold) do
    cond do
      baseline.std_duration_ms == 0 ->
        "Insufficient data for baseline comparison"

      deviation > threshold ->
        "Response time significantly slower than baseline (+#{Float.round(deviation / baseline.avg_duration_ms * 100, 1)}%)"

      deviation > threshold * 0.5 ->
        "Response time above normal range (+#{Float.round(deviation / baseline.avg_duration_ms * 100, 1)}%)"

      deviation < -threshold ->
        "Response time faster than baseline (#{Float.round(deviation / baseline.avg_duration_ms * 100, 1)}%)"

      true ->
        "Response time within normal range"
    end
  end

  defp do_get_metrics(url, limit, state) do
    case :ets.lookup(state.table, url) do
      [{^url, metrics}] ->
        Enum.take(metrics, limit)

      [] ->
        []
    end
  end

  defp do_get_stats(state) do
    urls = :ets.tab2list(state.table)
    total_metrics = Enum.reduce(urls, 0, fn {_, metrics}, acc -> acc + length(metrics) end)
    url_count = length(urls)

    %{
      total_metrics: total_metrics,
      url_count: url_count,
      urls: Enum.map(urls, fn {url, _} -> url end)
    }
  end
end
