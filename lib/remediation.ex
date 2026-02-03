defmodule Remediation do
  @moduledoc """
  Automated remediation system for handling unhealthy services.

  Provides functionality to detect unhealthy services and perform
  automated actions like restarts with proper safety checks and logging.
  """

  use GenServer
  require Logger

  @type remediation_action :: :restart_service | :run_playbook | :send_alert | :no_action
  @type remediation_status :: :pending | :running | :succeeded | :failed | :aborted

  defstruct queue: [],
            history: [],
            max_history: 100,
            enabled: true,
            safety_checks: true

  @doc """
  Start the remediation server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Check if a service is healthy.
  """
  def check_service_health(service_name, endpoint) do
    GenServer.call(__MODULE__, {:check_health, service_name, endpoint})
  end

  @doc """
  Attempt to restart an unhealthy service.
  """
  def restart_service(service_name, opts \\ []) do
    GenServer.call(__MODULE__, {:restart_service, service_name, opts})
  end

  @doc """
  Get remediation history.
  """
  def get_history(limit \\ 20) do
    GenServer.call(__MODULE__, {:get_history, limit})
  end

  @doc """
  Get current queue status.
  """
  def get_queue do
    GenServer.call(__MODULE__, :get_queue)
  end

  @doc """
  Enable or disable automatic remediation.
  """
  def set_enabled(enabled) do
    GenServer.call(__MODULE__, {:set_enabled, enabled})
  end

  @doc """
  Queue a remediation action.
  """
  def queue_remediation(service_name, action, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:queue_remediation, service_name, action, metadata})
  end

  @impl true
  def init(opts) do
    Logger.info("Starting Remediation Service")

    state = %__MODULE__{
      queue: :queue.new(),
      history: [],
      max_history: Keyword.get(opts, :max_history, 100),
      enabled: Keyword.get(opts, :enabled, true),
      safety_checks: Keyword.get(opts, :safety_checks, true)
    }

    Process.send_after(self(), :process_queue, 1000)

    {:ok, state}
  end

  @impl true
  def handle_call({:check_health, service_name, endpoint}, _from, state) do
    health_result = perform_health_check(service_name, endpoint)
    {:reply, health_result, state}
  end

  @impl true
  def handle_call({:restart_service, service_name, opts}, _from, state) do
    result = do_restart_service(service_name, opts, state)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_history, limit}, _from, state) do
    history = Enum.take(state.history, limit)
    {:reply, history, state}
  end

  @impl true
  def handle_call(:get_queue, _from, state) do
    queue_items = :queue.to_list(state.queue)
    {:reply, queue_items, state}
  end

  @impl true
  def handle_call({:set_enabled, enabled}, _from, state) do
    Logger.info("Remediation #{if enabled, do: "enabled", else: "disabled"}")
    {:reply, :ok, %{state | enabled: enabled}}
  end

  @impl true
  def handle_call({:queue_remediation, service_name, action, metadata}, _from, state) do
    item = %{
      id: generate_id(),
      service_name: service_name,
      action: action,
      metadata: metadata,
      status: :pending,
      queued_at: DateTime.utc_now(),
      attempts: 0
    }

    new_queue = :queue.in(item, state.queue)
    Logger.info("Queued remediation: #{action} for #{service_name}")

    {:reply, {:ok, item.id}, %{state | queue: new_queue}}
  end

  @impl true
  def handle_info(:process_queue, state) do
    new_state = process_next_item(state)
    Process.send_after(self(), :process_queue, 1000)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp process_next_item(state) do
    case :queue.out(state.queue) do
      {{:value, item}, remaining_queue} ->
        case execute_remediation(item, state) do
          {:ok, updated_item} ->
            new_history = [updated_item | state.history] |> Enum.take(state.max_history)
            %{state | queue: remaining_queue, history: new_history}

          {:error, reason} ->
            Logger.warning("Remediation failed: #{inspect(reason)}")
            updated_item = %{item | status: :failed, error: reason}
            new_history = [updated_item | state.history] |> Enum.take(state.max_history)
            %{state | queue: remaining_queue, history: new_history}
        end

      {:empty, _queue} ->
        state
    end
  end

  defp execute_remediation(item, state) do
    if not state.enabled do
      {:ok, %{item | status: :aborted, error: :remediation_disabled}}
    else
      Logger.info("Executing remediation: #{item.action} for #{item.service_name}")

      result =
        case item.action do
          :restart_service ->
            do_restart_service(item.service_name, item.metadata, state)

          :run_playbook ->
            execute_playbook(item.service_name, item.metadata)

          :send_alert ->
            send_remediation_alert(item.service_name, item.metadata)

          :no_action ->
            {:ok, %{item | status: :succeeded, outcome: %{message: "No action taken"}}}
        end

      case result do
        {:ok, outcome} ->
          updated_item = Map.put(item, :outcome, outcome)
          {:ok, %{updated_item | status: :succeeded, completed_at: DateTime.utc_now()}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp perform_health_check(service_name, endpoint) do
    Logger.debug("Checking health for #{service_name} at #{endpoint}")

    start_time = System.monotonic_time(:millisecond)

    result =
      try do
        case HTTPoison.get(endpoint, [], timeout: 5000, recv_timeout: 5000) do
          {:ok, %HTTPoison.Response{status_code: code}} when code in 200..299 ->
            {:ok, :healthy, code}

          {:ok, %HTTPoison.Response{status_code: code}} ->
            {:ok, :unhealthy, code}

          {:error, %HTTPoison.Error{reason: reason}} ->
            {:error, reason}
        end
      rescue
        e ->
          Logger.error("Health check error for #{service_name}: #{inspect(e)}")
          {:error, :exception}
      end

    duration = System.monotonic_time(:millisecond) - start_time

    case result do
      {:ok, status, code} ->
        Logger.info("Health check for #{service_name}: #{status} (#{code} in #{duration}ms)")
        {:ok, %{status: status, code: code, duration_ms: duration}}

      {:error, reason} ->
        Logger.warning("Health check failed for #{service_name}: #{inspect(reason)}")
        {:error, %{reason: reason, duration_ms: duration}}
    end
  end

  defp do_restart_service(service_name, opts, state) do
    Logger.info("Attempting to restart service: #{service_name}")

    if state.safety_checks and Keyword.get(opts, :skip_safety_checks, false) == false do
      case perform_safety_checks(service_name, opts, state) do
        {:error, reason} ->
          Logger.warning("Safety check failed for #{service_name}: #{inspect(reason)}")
          {:error, {:safety_check_failed, reason}}

        :ok ->
          :ok
      end
    else
      :ok
    end

    result = execute_restart(service_name, opts)

    case result do
      {:ok, _} ->
        Logger.info("✓ Service #{service_name} restarted successfully")
        notify_remediation_success(service_name, :restart)

      {:error, reason} ->
        Logger.error("✗ Failed to restart service #{service_name}: #{inspect(reason)}")
        notify_remediation_failure(service_name, :restart, reason)
    end

    result
  end

  defp perform_safety_checks(service_name, opts, state) do
    max_restarts = Keyword.get(opts, :max_restarts_per_hour, 10)

    recent_restarts =
      Enum.filter(state.history, fn item ->
        item.service_name == service_name and
          item.status == :succeeded and
          DateTime.diff(DateTime.utc_now(), item.queued_at, :second) < 3600
      end)

    if length(recent_restarts) >= max_restarts do
      {:error, :too_many_restarts}
    else
      Logger.debug("Safety check passed for #{service_name}")
      :ok
    end
  end

  defp execute_restart(service_name, opts) do
    grace_period = Keyword.get(opts, :grace_period, 5000)

    Logger.info("Grace period: #{grace_period}ms before restart")

    :timer.sleep(grace_period)

    Logger.info("Executing restart for #{service_name}")

    case execute_service_command(service_name, "restart", opts) do
      {0, _output} ->
        {:ok, %{action: :restart, service: service_name}}

      {code, output} ->
        {:error, %{exit_code: code, output: output}}
    end
  end

  defp execute_service_command(service_name, command, opts) do
    try do
      {output, exit_code} =
        System.cmd("systemctl", [command, service_name],
          stderr_to_stdout: true,
          into: []
        )

      {exit_code, IO.iodata_to_binary(output)}
    rescue
      e ->
        Logger.error("Failed to execute #{command} for #{service_name}: #{inspect(e)}")
        {1, "Command execution failed: #{inspect(e)}"}
    end
  end

  defp execute_playbook(service_name, metadata) do
    playbook_id = Map.get(metadata, :playbook_id)
    Logger.info("Executing playbook #{playbook_id} for #{service_name}")

    case Playbooks.run(playbook_id, metadata) do
      {:ok, result} ->
        Logger.info("✓ Playbook #{playbook_id} completed for #{service_name}")
        notify_remediation_success(service_name, :playbook)
        {:ok, result}

      {:error, reason} ->
        Logger.error("✗ Playbook #{playbook_id} failed for #{service_name}: #{inspect(reason)}")
        notify_remediation_failure(service_name, :playbook, reason)
        {:error, reason}
    end
  end

  defp send_remediation_alert(service_name, metadata) do
    Logger.info("Sending remediation alert for #{service_name}")

    notification =
      Notifications.Notification.new(%{
        title: "Remediation Alert: #{service_name}",
        message: Map.get(metadata, :message, "Automatic remediation required"),
        severity: Map.get(metadata, :severity, :warning),
        url: Map.get(metadata, :url),
        metadata: metadata
      })

    Notifications.Dispatcher.send(notification, [:slack, :email])

    {:ok, %{action: :alert_sent, service: service_name}}
  end

  defp notify_remediation_success(service_name, action) do
    notification =
      Notifications.Notification.new(%{
        title: "Remediation Successful: #{service_name}",
        message: "Successfully performed #{action} on #{service_name}",
        severity: :info,
        metadata: %{service: service_name, action: action}
      })

    Notifications.Dispatcher.send(notification, [:slack])
  end

  defp notify_remediation_failure(service_name, action, reason) do
    notification =
      Notifications.Notification.new(%{
        title: "Remediation Failed: #{service_name}",
        message: "Failed to perform #{action} on #{service_name}: #{inspect(reason)}",
        severity: :error,
        metadata: %{service: service_name, action: action, reason: inspect(reason)}
      })

    Notifications.Dispatcher.send(notification, [:slack, :email])
  end

  defp generate_id do
    "rem_#{System.unique_integer([:positive, :monotonic])}"
  end
end
