defmodule Notifications.Channel do
  @moduledoc """
  Protocol defining the interface for notification channels.

  Any notification channel (Slack, Email, SMS, etc.) must implement this protocol.
  This allows the system to easily add new notification methods.
  """

  @doc """
  Send a notification through this channel.

  Returns {:ok, result} on success, {:error, reason} on failure.
  """
  @callback send(notification :: Notifications.Notification.t()) ::
              {:ok, any()} | {:error, any()}

  @doc """
  Validate that the channel is properly configured and can send notifications.
  """
  @callback validate_config() :: :ok | {:error, any()}

  @doc """
  Get a human-readable name for this channel.
  """
  @callback name() :: String.t()

  @optional_callbacks [validate_config: 0, name: 0]
end
