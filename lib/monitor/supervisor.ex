defmodule Monitor.Supervisor do
  @moduledoc """
  Supervisor for the entire monitoring system.

  This is where Elixir's fault tolerance shines — if any endpoint checker
  crashes, the supervisor will automatically restart it. No manual recovery needed.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("Starting Monitor Supervisor")

    # Get initial endpoints from opts or environment
    endpoints = Keyword.get(opts, :endpoints, default_endpoints())
    # 30 seconds default
    check_interval = Keyword.get(opts, :check_interval, 30_000)

    children = [
      # Registry for naming processes and storing PID mappings
      {Registry, keys: :unique, name: Monitor.Registry},

      # LLM Router for intelligent alert routing and analysis
      LLMRouter,

      # Anomaly Detection for baseline tracking and anomaly identification
      AnomalyDetection,

      # Root Cause Analysis for correlating failures across endpoints
      RootCauseAnalysis,

      # Alert Deduplication for preventing spam notifications
      AlertDeduplication,

      # Coordinator aggregates results from all checkers
      Monitor.Coordinator,

      # Dynamic supervisor for endpoint checkers (can add/remove at runtime)
      {DynamicSupervisor, strategy: :one_for_one, name: Monitor.CheckerSupervisor}
    ]

    # Start children first
    children_specs = Supervisor.init(children, strategy: :one_for_one)

    # Start endpoint checkers after dynamic supervisor is ready
    spawn(fn ->
      # Small delay to ensure DynamicSupervisor is ready
      :timer.sleep(100)

      Enum.each(endpoints, fn url ->
        case DynamicSupervisor.start_child(
               Monitor.CheckerSupervisor,
               {Monitor.EndpointChecker, {url, Monitor.Coordinator, check_interval}}
             ) do
          {:ok, pid} ->
            Logger.info("✓ Started checker for #{url}")
            # Store PID mapping in registry
            Registry.register(Monitor.Registry, {:endpoint_pid, url}, pid)

          {:error, reason} ->
            Logger.error("✗ Failed to start checker for #{url}: #{inspect(reason)}")
        end
      end)
    end)

    children_specs
  end

  # Public API

  defp default_endpoints do
    [
      "https://example.com",
      "https://httpbin.org/status/200",
      "https://httpbin.org/delay/1"
    ]
  end

  @doc """
  Add a new endpoint to monitor
  """
  def add_endpoint(url, check_interval \\ 30_000) do
    case Monitor.Coordinator.register_endpoint(url) do
      :ok ->
        {:ok, pid} =
          DynamicSupervisor.start_child(
            Monitor.CheckerSupervisor,
            {Monitor.EndpointChecker, {url, Monitor.Coordinator, check_interval}}
          )

        Logger.info("Added new endpoint: #{url}")
        {:ok, pid}

      {:error, reason} ->
        Logger.error("Failed to register endpoint #{url}: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Remove an endpoint from monitoring
  """
  def remove_endpoint(url) do
    case Registry.lookup(Monitor.Registry, {:endpoint_checker, url}) do
      [{pid, _}] ->
        DynamicSupervisor.terminate_child(Monitor.CheckerSupervisor, pid)
        Logger.info("Removed endpoint: #{url}")
        :ok

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  List all monitored endpoints
  """
  def list_endpoints do
    Registry.select(Monitor.Registry, [
      {{{:endpoint_checker, :"$1"}, :_, :_}, [], [:"$1"]}
    ])
  end
end
