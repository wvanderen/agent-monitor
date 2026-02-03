defmodule Monitor.Coordinator do
  @moduledoc """
  Coordinates multiple endpoint checkers and aggregates results.

  Acts as the central hub where all agents report their findings.
  Can trigger alerts, store metrics, or make intelligent decisions
  based on aggregate data.
  """

  use GenServer
  require Logger

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Get all current check results
  """
  def get_results do
    GenServer.call(__MODULE__, :get_results)
  end

  @doc """
  Get results for a specific endpoint
  """
  def get_result(url) do
    GenServer.call(__MODULE__, {:get_result, url})
  end

  @doc """
  Register a new endpoint checker
  """
  def register_endpoint(url) do
    GenServer.call(__MODULE__, {:register_endpoint, url})
  end

  # Server Callbacks

  @impl true
  def init(_) do
    Logger.info("Starting Monitor Coordinator")

    state = %{
      # url => latest result
      endpoints: %{},
      registered_urls: MapSet.new(),
      intelligent_routing: true
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_results, _from, state) do
    {:reply, state.endpoints, state}
  end

  @impl true
  def handle_call({:get_result, url}, _from, state) do
    {:reply, Map.get(state.endpoints, url), state}
  end

  @impl true
  def handle_call({:register_endpoint, url}, _from, state) do
    if MapSet.member?(state.registered_urls, url) do
      {:reply, {:error, :already_registered}, state}
    else
      new_state = %{state | registered_urls: MapSet.put(state.registered_urls, url)}
      {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_info({:check_result, url, result}, state) do
    Logger.info("Result from #{url}: #{result.status}")

    # Store result with timestamp
    updated_endpoint =
      Map.get(state.endpoints, url, %{
        url: url,
        last_result: nil,
        last_check: nil,
        check_count: 0,
        failure_count: 0,
        consecutive_failures: 0,
        history: [],
        metrics: %{}
      })

    failure_count = if(result.status == :error, do: updated_endpoint.failure_count + 1, else: 0)

    consecutive_failures =
      if(result.status == :error, do: updated_endpoint.consecutive_failures + 1, else: 0)

    updated_endpoint =
      Map.merge(updated_endpoint, %{
        last_result: result,
        last_check: DateTime.utc_now(),
        check_count: updated_endpoint.check_count + 1,
        failure_count: failure_count,
        consecutive_failures: consecutive_failures,
        # Keep last 10
        history: [result | Enum.take(updated_endpoint.history, 9)]
      })

    # Intelligent routing integration
    if state.intelligent_routing do
      process_intelligent_routing(url, result, updated_endpoint)
    end

    new_state = %{state | endpoints: Map.put(state.endpoints, url, updated_endpoint)}

    {:noreply, new_state}
  end

  def handle_info({:llm_route_result, url, severity, suggestions}, state) do
    Logger.info("LLM routing result for #{url}: #{LLMRouter.Severity.to_string(severity)}")

    case AlertDeduplication.should_send_alert(url, nil, severity) do
      {:ok, true} ->
        AlertDeduplication.record_alert(url, nil, severity)
        log_intelligent_alert(url, severity, suggestions)
        send_notification(url, severity, suggestions, state)

      {:ok, false} ->
        Logger.debug("Alert deduplicated for #{url}")
    end

    {:noreply, state}
  end

  # Private Functions

  defp process_intelligent_routing(url, result, endpoint_data) do
    # Record metric for anomaly detection
    AnomalyDetection.record_metric(url, result)

    # Record failure for root cause analysis if error
    if result.status == :error do
      RootCauseAnalysis.record_failure(url, result)
    end

    # LLM routing for severity classification and recovery suggestions
    if result.status == :error or endpoint_data.consecutive_failures > 0 do
      failure_data = %{
        reason: Map.get(result, :reason),
        code: Map.get(result, :code),
        duration_ms: Map.get(result, :duration_ms),
        consecutive_failures: endpoint_data.consecutive_failures
      }

      spawn(fn ->
        case LLMRouter.classify_severity(url, failure_data) do
          {:ok, severity} ->
            {:ok, suggestions} = LLMRouter.get_recovery_suggestions(url, failure_data)
            send(self(), {:llm_route_result, url, severity, suggestions})

          {:error, _reason} ->
            Logger.debug("LLM classification failed for #{url}")
        end
      end)
    end
  end

  defp log_intelligent_alert(url, severity, suggestions) when is_list(suggestions) do
    severity_str = LLMRouter.Severity.to_string(severity)
    Logger.warning("🚨 [#{severity_str}] Intelligent Alert: #{url}")

    Enum.with_index(suggestions, fn suggestion, idx ->
      Logger.warning("  #{idx + 1}. #{suggestion}")
    end)
  end

  defp log_intelligent_alert(url, severity, _suggestions) do
    severity_str = LLMRouter.Severity.to_string(severity)
    Logger.warning("🚨 [#{severity_str}] Intelligent Alert: #{url}")
  end

  defp send_notification(url, severity, suggestions, _state) do
    notification =
      Notifications.Notification.new(%{
        title: "Alert: #{url}",
        message: build_notification_message(url, severity, suggestions),
        severity: severity,
        url: url,
        metadata: %{
          suggestions: suggestions,
          severity: LLMRouter.Severity.to_string(severity)
        }
      })

    Notifications.Dispatcher.send(notification)
  end

  defp build_notification_message(url, severity, suggestions) when is_list(suggestions) do
    severity_str = LLMRouter.Severity.to_string(severity)
    suggestion_list = Enum.map_join(suggestions, "\n", &"- #{&1}")

    """
    Endpoint: #{url}
    Severity: #{severity_str}

    Recovery Suggestions:
    #{suggestion_list}
    """
  end

  defp build_notification_message(url, severity, _suggestions) do
    severity_str = LLMRouter.Severity.to_string(severity)

    """
    Endpoint: #{url}
    Severity: #{severity_str}
    """
  end
end
