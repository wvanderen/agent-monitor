defmodule RootCauseAnalysis do
  @moduledoc """
  Root Cause Analysis module for correlating failures across multiple endpoints.

  Identifies patterns in failures, stores failure patterns, and correlates
  issues across the monitored system.
  """

  use GenServer
  require Logger

  @ets_table :failure_patterns
  @pattern_window 100
  @correlation_threshold 0.7

  defmodule FailureEvent do
    @moduledoc """
    Structure for individual failure events.
    """
    defstruct [
      :url,
      :timestamp,
      :status_code,
      :error_reason,
      :duration_ms,
      :correlation_id
    ]

    @doc """
    Create a new failure event.
    """
    def new(url, result, correlation_id \\ nil) do
      %__MODULE__{
        url: url,
        timestamp: DateTime.utc_now(),
        status_code: Map.get(result, :code),
        error_reason: Map.get(result, :reason),
        duration_ms: Map.get(result, :duration_ms, 0),
        correlation_id: correlation_id || generate_correlation_id()
      }
    end

    defp generate_correlation_id do
      :crypto.strong_rand_bytes(8)
      |> Base.encode16(case: :lower)
    end
  end

  defmodule FailurePattern do
    @moduledoc """
    Pattern of correlated failures.
    """
    defstruct [
      :pattern_id,
      :affected_endpoints,
      :common_error_reasons,
      :time_window,
      :frequency,
      :first_seen,
      :last_seen,
      :description
    ]

    @doc """
    Create a pattern from a list of failure events.
    """
    def from_events(events) when is_list(events) and length(events) > 0 do
      endpoints = Enum.uniq_by(events, & &1.url) |> Enum.map(& &1.url)
      error_reasons = Enum.uniq_by(events, & &1.error_reason) |> Enum.map(& &1.error_reason)

      timestamps = Enum.map(events, & &1.timestamp)
      first_seen = Enum.min(timestamps, DateTime)
      last_seen = Enum.max(timestamps, DateTime)

      time_window = DateTime.diff(last_seen, first_seen)

      %__MODULE__{
        pattern_id: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower),
        affected_endpoints: endpoints,
        common_error_reasons: error_reasons,
        time_window: time_window,
        frequency: length(events),
        first_seen: first_seen,
        last_seen: last_seen,
        description: generate_description(endpoints, error_reasons, length(events))
      }
    end

    defp generate_description(endpoints, errors, count) do
      "Pattern affecting #{length(endpoints)} endpoint(s) with #{length(errors)} distinct error types (#{count} total failures)"
    end
  end

  defmodule CorrelationReport do
    @moduledoc """
    Report of correlated failures and root cause analysis.
    """
    defstruct [
      :url,
      :correlation_id,
      :related_endpoints,
      :pattern_id,
      :likelihood,
      :root_cause_hypothesis,
      :suggested_actions
    ]
  end

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Record a failure event for analysis.
  """
  def record_failure(url, result, correlation_id \\ nil) do
    event = FailureEvent.new(url, result, correlation_id)
    GenServer.cast(__MODULE__, {:record_failure, event})
  end

  @doc """
  Analyze failures and find correlations.
  """
  def analyze_correlations(url) do
    GenServer.call(__MODULE__, {:analyze_correlations, url})
  end

  @doc """
  Get all failure patterns.
  """
  def get_patterns do
    GenServer.call(__MODULE__, :get_patterns)
  end

  @doc """
  Get failure events for an endpoint.
  """
  def get_events(url, limit \\ 50) do
    GenServer.call(__MODULE__, {:get_events, url, limit})
  end

  @doc """
  Find root cause for a specific failure.
  """
  def find_root_cause(url, result) do
    GenServer.call(__MODULE__, {:find_root_cause, url, result})
  end

  @doc """
  Get analysis statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    Logger.info("Starting Root Cause Analysis Service")

    patterns_table = :ets.new(@ets_table, [:named_table, :set, :private, read_concurrency: true])

    events_table =
      :ets.new(:failure_events, [:named_table, :bag, :private, read_concurrency: true])

    state = %{
      patterns_table: patterns_table,
      events_table: events_table,
      pattern_window: @pattern_window,
      correlation_threshold: @correlation_threshold
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:record_failure, event}, state) do
    do_record_failure(event, state)
    {:noreply, state}
  end

  @impl true
  def handle_call({:analyze_correlations, url}, _from, state) do
    report = do_analyze_correlations(url, state)
    {:reply, report, state}
  end

  @impl true
  def handle_call(:get_patterns, _from, state) do
    patterns = :ets.tab2list(state.patterns_table)
    {:reply, patterns, state}
  end

  @impl true
  def handle_call({:get_events, url, limit}, _from, state) do
    events = do_get_events(url, limit, state)
    {:reply, events, state}
  end

  @impl true
  def handle_call({:find_root_cause, url, result}, _from, state) do
    report = do_find_root_cause(url, result, state)
    {:reply, report, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = do_get_stats(state)
    {:reply, stats, state}
  end

  # Private Functions

  defp do_record_failure(event, state) do
    :ets.insert(state.events_table, {event.url, event})

    correlate_and_update_patterns(event, state)
  end

  defp correlate_and_update_patterns(event, state) do
    recent_events = get_recent_events(state.pattern_window, state)

    correlated = find_correlated_events(event, recent_events, state.correlation_threshold)

    if length(correlated) > 0 do
      all_events = [event | correlated]
      pattern = FailurePattern.from_events(all_events)

      :ets.insert(state.patterns_table, {pattern.pattern_id, pattern})

      Logger.debug("Detected failure pattern: #{pattern.description}")
    end
  end

  defp get_recent_events(window, state) do
    :ets.tab2list(state.events_table)
    |> Enum.take(window)
    |> Enum.map(fn {_, event} -> event end)
  end

  defp find_correlated_events(event, events, threshold) do
    cutoff_time = DateTime.add(event.timestamp, -60)

    events
    |> Enum.filter(fn e ->
      DateTime.after?(e.timestamp, cutoff_time)
    end)
    |> Enum.filter(fn e ->
      calculate_correlation(event, e) >= threshold
    end)
  end

  defp calculate_correlation(event1, event2) do
    score = 0

    score = score + if event1.error_reason == event2.error_reason, do: 0.4, else: 0
    score = score + if similar_url?(event1.url, event2.url), do: 0.3, else: 0
    score = score + if close_timestamps?(event1.timestamp, event2.timestamp), do: 0.3, else: 0

    min(score, 1.0)
  end

  defp similar_url?(url1, url2) do
    host1 = extract_host(url1)
    host2 = extract_host(url2)

    host1 == host2 && host1 != nil
  end

  defp extract_host(url) do
    case URI.parse(url) do
      %{host: host} when is_binary(host) -> host
      _ -> nil
    end
  end

  defp close_timestamps?(ts1, ts2) do
    diff = abs(DateTime.diff(ts1, ts2))
    diff <= 30
  end

  defp do_analyze_correlations(url, state) do
    events = do_get_events(url, 50, state)
    patterns = :ets.tab2list(state.patterns_table) |> Enum.map(fn {_, p} -> p end)

    relevant_patterns =
      patterns
      |> Enum.filter(fn p ->
        Enum.member?(p.affected_endpoints, url)
      end)
      |> Enum.sort_by(fn p -> p.frequency end, :desc)

    related_endpoints =
      events
      |> Enum.flat_map(fn e ->
        patterns
        |> Enum.filter(fn p ->
          Enum.member?(p.affected_endpoints, url) and Enum.member?(p.affected_endpoints, e.url)
        end)
        |> Enum.map(fn p -> p.affected_endpoints end)
      end)
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.reject(&(&1 == url))

    correlation_report = %CorrelationReport{
      url: url,
      correlation_id: generate_id(),
      related_endpoints: related_endpoints,
      pattern_id:
        if(length(relevant_patterns) > 0, do: hd(relevant_patterns).pattern_id, else: nil),
      likelihood: calculate_likelihood(events, relevant_patterns),
      root_cause_hypothesis: generate_hypothesis(events, relevant_patterns),
      suggested_actions: generate_actions(events, relevant_patterns)
    }

    {:ok, correlation_report}
  end

  defp calculate_likelihood(events, patterns) do
    if length(events) == 0 do
      0.0
    else
      pattern_score = min(length(patterns) * 0.3, 0.9)
      event_score = min(length(events) * 0.1, 0.7)
      min(pattern_score + event_score, 1.0)
    end
  end

  defp generate_hypothesis(events, patterns) do
    cond do
      length(patterns) > 0 ->
        pattern = hd(patterns)

        "Likely correlated with #{length(pattern.affected_endpoints)} other endpoint(s). Common cause: #{Enum.join(pattern.common_error_reasons, ", ")}"

      length(events) > 10 ->
        "Multiple failures detected. Possible infrastructure or network issue."

      true ->
        "Isolated failure event."
    end
  end

  defp generate_actions(events, patterns) do
    actions = []

    actions =
      if length(patterns) > 0 do
        ["Check shared infrastructure dependencies", "Review recent deployments" | actions]
      else
        actions
      end

    actions =
      if length(events) > 5 do
        ["Investigate recurring error pattern", "Check service health status" | actions]
      else
        actions
      end

    actions =
      if length(events) == 1 do
        ["Verify endpoint availability", "Check network connectivity" | actions]
      else
        actions
      end

    Enum.uniq(actions)
  end

  defp do_get_events(url, limit, state) do
    :ets.lookup(state.events_table, url)
    |> Enum.map(fn {_, event} -> event end)
    |> Enum.take(limit)
  end

  defp do_find_root_cause(url, result, state) do
    event = FailureEvent.new(url, result)
    events = do_get_events(url, 50, state)

    report = %CorrelationReport{
      url: url,
      correlation_id: event.correlation_id,
      related_endpoints: [],
      pattern_id: nil,
      likelihood: 0.5,
      root_cause_hypothesis: "Analysis based on single failure event",
      suggested_actions: [
        "Check endpoint logs for detailed error information",
        "Verify service availability and connectivity",
        "Review recent changes to the endpoint"
      ]
    }

    {:ok, report}
  end

  defp do_get_stats(state) do
    event_count = :ets.info(state.events_table, :size)
    pattern_count = :ets.info(state.patterns_table, :size)

    %{
      total_events: event_count,
      total_patterns: pattern_count,
      urls_tracked:
        :ets.foldl(fn {url, _}, acc -> MapSet.put(acc, url) end, MapSet.new(), state.events_table)
        |> MapSet.size()
    }
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
