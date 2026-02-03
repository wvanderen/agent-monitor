defmodule Notifications.Notification do
  @moduledoc """
  Struct representing a notification to be sent.

  Contains all the information a channel might need to send a notification.
  """

  @type severity :: :info | :warning | :error | :critical
  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          message: String.t(),
          severity: severity,
          url: String.t() | nil,
          metadata: map(),
          timestamp: DateTime.t()
        }

  defstruct [
    :id,
    :title,
    :message,
    :severity,
    :url,
    :metadata,
    :timestamp
  ]

  @doc """
  Create a new notification struct.
  """
  def new(attrs) do
    %__MODULE__{
      id: Map.get(attrs, :id, generate_id()),
      title: Map.get(attrs, :title),
      message: Map.get(attrs, :message),
      severity: Map.get(attrs, :severity, :info),
      url: Map.get(attrs, :url),
      metadata: Map.get(attrs, :metadata, %{}),
      timestamp: Map.get(attrs, :timestamp, DateTime.utc_now())
    }
  end

  defp generate_id do
    "notif_#{System.unique_integer([:positive, :monotonic])}"
  end

  @doc """
  Format severity for display.
  """
  def severity_string(severity) when is_atom(severity) do
    case severity do
      :info -> "INFO"
      :warning -> "WARNING"
      :error -> "ERROR"
      :critical -> "CRITICAL"
      _ -> "UNKNOWN"
    end
  end
end
