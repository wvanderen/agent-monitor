defmodule AlertDeduplication do
  @moduledoc """
  Alert Deduplication module to prevent spam notifications for known issues.

  Implements time-window based deduplication to ensure that duplicate alerts
  for the same issue within a configured time window are not sent.
  """

  use GenServer
  require Logger

  @ets_table :alert_cache
  @default_time_window 5 * 60
  @default_cache_ttl 10 * 60

  defmodule AlertInfo do
    @moduledoc """
    Information about an alert for deduplication.
    """
    defstruct [
      :url,
      :alert_key,
      :severity,
      :first_seen,
      :last_seen,
      :count,
      :reason,
      :last_result
    ]

    @doc """
    Create an alert info record.
    """
    def new(url, result, severity \\ :warning) do
      alert_key = generate_alert_key(url, result)
      now = DateTime.utc_now()

      %__MODULE__{
        url: url,
        alert_key: alert_key,
        severity: severity,
        first_seen: now,
        last_seen: now,
        count: 1,
        reason: Map.get(result, :reason),
        last_result: result
      }
    end

    defp generate_alert_key(url, result) do
      reason = Map.get(result, :reason, "")
      code = Map.get(result, :code)

      "#{url}:#{code}:#{reason}"
    end
  end

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Check if an alert should be sent (not duplicate within time window).
  """
  def should_send_alert(url, result, severity \\ :warning) do
    GenServer.call(__MODULE__, {:should_send_alert, url, result, severity})
  end

  @doc """
  Record an alert (regardless of whether it was sent).
  """
  def record_alert(url, result, severity \\ :warning) do
    GenServer.cast(__MODULE__, {:record_alert, url, result, severity})
  end

  @doc """
  Get alert info for a URL.
  """
  def get_alert_info(url) do
    GenServer.call(__MODULE__, {:get_alert_info, url})
  end

  @doc """
  Clear cached alert for a URL.
  """
  def clear_alert(url) do
    GenServer.cast(__MODULE__, {:clear_alert, url})
  end

  @doc """
  Clear all cached alerts.
  """
  def clear_all_alerts do
    GenServer.cast(__MODULE__, :clear_all_alerts)
  end

  @doc """
  Get deduplication statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server Callbacks

  @impl true
  def init(_) do
    Logger.info("Starting Alert Deduplication Service")

    table = :ets.new(@ets_table, [:named_table, :set, :private, read_concurrency: true])

    state = %{
      table: table,
      time_window: get_time_window(),
      cache_ttl: get_cache_ttl(),
      deduplicated_count: 0,
      sent_count: 0
    }

    schedule_cleanup(state.cache_ttl)

    {:ok, state}
  end

  @impl true
  def handle_cast({:record_alert, url, result, severity}, state) do
    do_record_alert(url, result, severity, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:clear_alert, url}, state) do
    :ets.delete(state.table, url)
    Logger.debug("Cleared alert for endpoint: #{url}")
    {:noreply, state}
  end

  @impl true
  def handle_cast(:clear_all_alerts, state) do
    :ets.delete_all_objects(state.table)
    Logger.debug("Cleared all cached alerts")
    {:noreply, state}
  end

  @impl true
  def handle_cast(:cleanup_expired, state) do
    do_cleanup_expired(state)
    schedule_cleanup(state.cache_ttl)
    {:noreply, state}
  end

  @impl true
  def handle_call({:should_send_alert, url, result, severity}, _from, state) do
    should_send = do_should_send_alert(url, result, severity, state)

    if should_send do
      new_state = %{state | sent_count: state.sent_count + 1}
      {:reply, {:ok, true}, new_state}
    else
      new_state = %{state | deduplicated_count: state.deduplicated_count + 1}
      {:reply, {:ok, false}, new_state}
    end
  end

  @impl true
  def handle_call({:get_alert_info, url}, _from, state) do
    case :ets.lookup(state.table, url) do
      [{^url, alert_info}] ->
        {:reply, {:ok, alert_info}, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      sent_count: state.sent_count,
      deduplicated_count: state.deduplicated_count,
      time_window_seconds: state.time_window,
      cached_alerts: :ets.info(state.table, :size)
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    do_cleanup_expired(state)
    schedule_cleanup(state.cache_ttl)
    {:noreply, state}
  end

  # Private Functions

  defp do_record_alert(url, result, severity, state) do
    alert_key = AlertInfo.new(url, result, severity).alert_key

    case :ets.lookup(state.table, url) do
      [{^url, existing}] ->
        if existing.alert_key == alert_key do
          updated = %{
            existing
            | last_seen: DateTime.utc_now(),
              count: existing.count + 1,
              last_result: result
          }

          :ets.insert(state.table, {url, updated})
        else
          new_alert = AlertInfo.new(url, result, severity)
          :ets.insert(state.table, {url, new_alert})
          Logger.debug("New alert type for #{url}: #{alert_key}")
        end

      [] ->
        new_alert = AlertInfo.new(url, result, severity)
        :ets.insert(state.table, {url, new_alert})
    end
  end

  defp do_should_send_alert(url, result, severity, state) do
    alert_key = AlertInfo.new(url, result, severity).alert_key
    now = DateTime.utc_now()

    case :ets.lookup(state.table, url) do
      [{^url, existing}] ->
        if existing.alert_key == alert_key do
          time_since_last = DateTime.diff(now, existing.last_seen)
          time_since_first = DateTime.diff(now, existing.first_seen)

          cond do
            time_since_last > state.time_window ->
              true

            time_since_first > state.time_window ->
              Logger.debug(
                "Alert deduplicated for #{url} (last seen #{time_since_last}s ago, count: #{existing.count})"
              )

              false

            true ->
              Logger.debug("Alert deduplicated for #{url} (within time window)")
              false
          end
        else
          true
        end

      [] ->
        true
    end
  end

  defp do_cleanup_expired(state) do
    now = DateTime.utc_now()
    cutoff = DateTime.add(now, -state.cache_ttl)

    expired_urls =
      :ets.foldl(
        fn {url, alert_info}, acc ->
          if DateTime.compare(alert_info.last_seen, cutoff) == :lt do
            [url | acc]
          else
            acc
          end
        end,
        [],
        state.table
      )

    Enum.each(expired_urls, fn url ->
      :ets.delete(state.table, url)
      Logger.debug("Cleaned up expired alert for: #{url}")
    end)

    if length(expired_urls) > 0 do
      Logger.info("Cleaned up #{length(expired_urls)} expired alerts")
    end
  end

  defp schedule_cleanup(interval) do
    Process.send_after(self(), :cleanup, interval * 1000)
  end

  defp get_time_window do
    case Application.get_env(:agent_monitor, :alert_dedup_window) do
      seconds when is_integer(seconds) and seconds > 0 -> seconds
      _ -> @default_time_window
    end
  end

  defp get_cache_ttl do
    case Application.get_env(:agent_monitor, :alert_cache_ttl) do
      seconds when is_integer(seconds) and seconds > 0 -> seconds
      _ -> @default_cache_ttl
    end
  end
end
