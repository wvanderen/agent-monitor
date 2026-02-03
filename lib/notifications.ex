defmodule Notifications do
  @moduledoc """
  Top-level module for notifications system.

  Provides notification creation and dispatch functionality
  across multiple channels (email, Slack, etc.).
  """

  alias Notifications.Notification
  alias Notifications.Dispatcher

  @doc """
  Create a new notification with the given attributes.
  """
  defdelegate new(attrs), to: Notification

  @doc """
  Send a notification through default channels.
  """
  defdelegate send(notification, channels \\ nil), to: Dispatcher

  @doc """
  Send a notification synchronously.
  """
  defdelegate send_sync(notification, channels \\ nil, timeout \\ 5000), to: Dispatcher

  @doc """
  Register a notification channel.
  """
  defdelegate register_channel(name, module, config \\ %{}, opts \\ []), to: Dispatcher

  @doc """
  Unregister a notification channel.
  """
  defdelegate unregister_channel(name), to: Dispatcher

  @doc """
  Set default channels for severity levels.
  """
  defdelegate set_defaults(defaults), to: Dispatcher

  @doc """
  List registered channels.
  """
  defdelegate list_channels, to: Dispatcher

  @doc """
  Get channel configuration.
  """
  defdelegate get_channel(name), to: Dispatcher
end
