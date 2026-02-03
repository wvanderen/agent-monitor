defmodule Notifications.Dispatcher do
  @moduledoc """
  Dispatcher for sending notifications through multiple channels.

  Manages registered notification channels and dispatches notifications
  based on severity and configuration.
  """

  use GenServer
  require Logger

  alias Notifications.{Channel, Notification}

  @type channel_config :: %{
          name: atom(),
          module: module(),
          enabled: boolean(),
          config: map()
        }

  defstruct channels: %{},
            default_channels: [],
            rate_limiter: nil

  @doc """
  Start the notification dispatcher.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Send a notification through enabled channels.

  Channels can be specified explicitly, or defaults will be used based on severity.
  """
  def send(notification, channels \\ nil) do
    GenServer.cast(__MODULE__, {:send, notification, channels})
  end

  @doc """
  Send a notification synchronously and return results.
  """
  def send_sync(notification, channels \\ nil, timeout \\ 5000) do
    GenServer.call(__MODULE__, {:send_sync, notification, channels}, timeout)
  end

  @doc """
  Register a new notification channel.
  """
  def register_channel(name, module, config \\ %{}, opts \\ []) do
    enabled = Keyword.get(opts, :enabled, true)
    GenServer.call(__MODULE__, {:register_channel, name, module, config, enabled})
  end

  @doc """
  Unregister a notification channel.
  """
  def unregister_channel(name) do
    GenServer.call(__MODULE__, {:unregister_channel, name})
  end

  @doc """
  Set default channels for specific severity levels.
  """
  def set_defaults(defaults) when is_map(defaults) do
    GenServer.call(__MODULE__, {:set_defaults, defaults})
  end

  @doc """
  Get list of registered channels.
  """
  def list_channels do
    GenServer.call(__MODULE__, :list_channels)
  end

  @doc """
  Get channel configuration.
  """
  def get_channel(name) do
    GenServer.call(__MODULE__, {:get_channel, name})
  end

  @impl true
  def init(opts) do
    Logger.info("Starting Notification Dispatcher")

    state = %__MODULE__{
      channels: %{},
      default_channels: Keyword.get(opts, :defaults, []),
      rate_limiter: start_rate_limiter()
    }

    {:ok, state}
  end

  @impl true
  def handle_cast({:send, notification, channels}, state) do
    target_channels = determine_channels(notification, channels, state)

    Enum.each(target_channels, fn channel_name ->
      send_to_channel(channel_name, notification, state)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:send_sync, notification, channels}, _from, state) do
    target_channels = determine_channels(notification, channels, state)

    results =
      Enum.map(target_channels, fn channel_name ->
        {channel_name, send_to_channel(channel_name, notification, state)}
      end)

    {:reply, results, state}
  end

  @impl true
  def handle_call({:register_channel, name, module, config, enabled}, _from, state) do
    Logger.info("Registering channel: #{inspect(name)} (#{inspect(module)})")

    channel_config = %{
      name: name,
      module: module,
      enabled: enabled,
      config: config
    }

    new_state = %{state | channels: Map.put(state.channels, name, channel_config)}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:unregister_channel, name}, _from, state) do
    Logger.info("Unregistering channel: #{inspect(name)}")

    new_state = %{state | channels: Map.delete(state.channels, name)}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:set_defaults, defaults}, _from, state) do
    Logger.info("Setting default channels: #{inspect(defaults)}")
    {:reply, :ok, %{state | default_channels: defaults}}
  end

  @impl true
  def handle_call(:list_channels, _from, state) do
    channels =
      state.channels
      |> Enum.filter(fn {_name, config} -> config.enabled end)
      |> Enum.map(fn {_name, config} -> config end)

    {:reply, channels, state}
  end

  @impl true
  def handle_call({:get_channel, name}, _from, state) do
    {:reply, Map.get(state.channels, name), state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp determine_channels(notification, nil, state) do
    case Map.get(state.default_channels, notification.severity, []) do
      channels when is_list(channels) ->
        Enum.filter(channels, fn name ->
          case Map.get(state.channels, name) do
            %{enabled: true} -> true
            _ -> false
          end
        end)

      channels when is_atom(channels) ->
        channels
        |> List.wrap()
        |> Enum.filter(fn name ->
          case Map.get(state.channels, name) do
            %{enabled: true} -> true
            _ -> false
          end
        end)

      _ ->
        []
    end
  end

  defp determine_channels(_notification, channels, state) when is_list(channels) do
    Enum.filter(channels, fn name ->
      case Map.get(state.channels, name) do
        %{enabled: true} -> true
        _ -> false
      end
    end)
  end

  defp determine_channels(_notification, channel, state) when is_atom(channel) do
    case Map.get(state.channels, channel) do
      %{enabled: true} -> [channel]
      _ -> []
    end
  end

  defp send_to_channel(channel_name, notification, state) do
    case Map.get(state.channels, channel_name) do
      %{module: module} = config ->
        Logger.debug("Sending notification to #{channel_name}: #{notification.title}")

        case module.send(notification) do
          {:ok, result} ->
            Logger.info("✓ Notification sent via #{channel_name}")
            {:ok, result}

          {:error, reason} ->
            Logger.error("✗ Failed to send via #{channel_name}: #{inspect(reason)}")
            {:error, reason}
        end

      nil ->
        Logger.warning("Channel not found: #{channel_name}")
        {:error, :channel_not_found}
    end
  end

  defp start_rate_limiter do
    # Simple rate limiter could be implemented here
    # For now, return nil
    nil
  end
end
