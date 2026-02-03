defmodule Monitor.EndpointChecker do
  @moduledoc """
  A GenServer that continuously monitors a single endpoint.

  This is a "simplest possible agent" — it runs independently,
  handles its own state, and reports back to a coordinator.
  """

  use GenServer
  require Logger

  # Client API

  def start_link({url, coordinator, check_interval}) do
    GenServer.start_link(__MODULE__, {url, coordinator, check_interval})
  end

  @doc """
  Manually trigger a check (useful for testing)
  """
  def check_now(pid) do
    GenServer.cast(pid, :check)
  end

  @doc """
  Get current state
  """
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Server Callbacks

  @impl true
  def init({url, coordinator, check_interval}) do
    Logger.info("Starting EndpointChecker for #{url}")

    # Schedule first check
    schedule_check(check_interval)

    state = %{
      url: url,
      coordinator: coordinator,
      check_interval: check_interval,
      status: :initializing,
      last_check: nil,
      last_result: nil,
      check_count: 0,
      failure_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_cast(:check, state) do
    new_state = perform_check(state)
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:check, state) do
    new_state = perform_check(state)
    schedule_check(state.check_interval)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Private Functions

  defp perform_check(state) do
    Logger.debug("Checking #{state.url}")

    result = check_endpoint(state.url)

    new_state = %{
      state
      | last_check: DateTime.utc_now(),
        last_result: result,
        check_count: state.check_count + 1,
        status: if(result.status == :ok, do: :healthy, else: :unhealthy),
        failure_count: if(result.status == :ok, do: 0, else: state.failure_count + 1)
    }

    # Report to coordinator
    send(state.coordinator, {:check_result, state.url, result})

    new_state
  end

  defp check_endpoint(url) do
    start_time = System.monotonic_time(:millisecond)

    case HTTPoison.get(url, [], follow_redirect: true, timeout: 5000) do
      {:ok, %{status_code: code, body: body, headers: headers}} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        if code >= 200 and code < 300 do
          %{
            status: :ok,
            code: code,
            duration_ms: duration,
            body_size: byte_size(body),
            headers: headers
          }
        else
          %{
            status: :error,
            code: code,
            duration_ms: duration,
            reason: "HTTP #{code}"
          }
        end

      {:error, %{reason: reason}} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time

        %{
          status: :error,
          code: nil,
          duration_ms: duration,
          reason: inspect(reason)
        }
    end
  end

  defp schedule_check(interval) do
    Process.send_after(self(), :check, interval)
  end
end
