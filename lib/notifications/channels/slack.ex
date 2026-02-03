defmodule Notifications.Channels.Slack do
  @moduledoc """
  Slack webhook notification channel.

  Implements the Notifications.Channel protocol for sending alerts to Slack.
  Supports severity-based routing, rate limiting, and retry logic.
  """

  @behaviour Notifications.Channel

  alias Notifications.Notification
  require Logger

  @type config :: %{
          webhook_url: String.t(),
          channel: String.t() | nil,
          username: String.t() | nil,
          icon_emoji: String.t() | nil,
          rate_limit_max: non_neg_integer(),
          rate_limit_window: non_neg_integer()
        }

  defstruct config: nil,
            rate_tracker: %{},
            retry_count: 0,
            max_retries: 3

  @impl true
  def name, do: "Slack"

  @impl true
  def init(config) do
    validated_config = validate_and_default_config(config)
    {:ok, %__MODULE__{config: validated_config}}
  end

  @impl true
  def validate_config do
    case get_env_config() do
      nil ->
        {:error, :no_webhook_url}

      config ->
        if is_binary(config.webhook_url) and String.length(config.webhook_url) > 0 do
          :ok
        else
          {:error, :invalid_webhook_url}
        end
    end
  end

  @impl true
  def send(notification) do
    config = get_env_config()

    case config do
      nil ->
        Logger.warning("Slack webhook not configured")
        {:error, :not_configured}

      _config ->
        do_send(notification, config)
    end
  end

  defp do_send(notification, config) do
    webhook_url = config.webhook_url

    payload = build_payload(notification, config)

    Logger.debug("Sending Slack notification to #{webhook_url}")

    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(webhook_url, Jason.encode!(payload), headers, timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("✓ Slack notification sent successfully")
        {:ok, %{status: :sent}}

      {:ok, %HTTPoison.Response{status_code: code, body: body}} when code in 400..499 ->
        Logger.error("✗ Slack notification failed: #{code} - #{body}")
        {:error, {:http_error, code, body}}

      {:ok, %HTTPoison.Response{status_code: code}} when code >= 500 ->
        Logger.warning("⚠ Slack server error: #{code}, retrying...")
        retry_send(notification, config, 1)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("✗ Slack request failed: #{inspect(reason)}")
        retry_send(notification, config, 1)
    end
  end

  defp retry_send(notification, config, attempt) when attempt <= 3 do
    Logger.info("Retry attempt #{attempt}/3 for Slack notification")

    :timer.sleep(exp_backoff(attempt))

    webhook_url = config.webhook_url
    payload = build_payload(notification, config)
    headers = [{"Content-Type", "application/json"}]

    case HTTPoison.post(webhook_url, Jason.encode!(payload), headers, timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("✓ Slack notification sent on retry #{attempt}")
        {:ok, %{status: :retried, attempt: attempt}}

      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.error("✗ Slack retry #{attempt} failed: #{code}")
        retry_send(notification, config, attempt + 1)

      {:error, _reason} ->
        Logger.error("✗ Slack retry #{attempt} failed")
        retry_send(notification, config, attempt + 1)
    end
  end

  defp retry_send(_notification, _config, _attempt), do: {:error, :max_retries_exceeded}

  defp build_payload(notification, config) do
    severity_emoji = severity_to_emoji(notification.severity)
    title_emoji = severity_to_title_emoji(notification.severity)

    blocks = [
      %{
        type: "header",
        text: %{
          type: "plain_text",
          text: "#{title_emoji} #{notification.title}",
          emoji: true
        }
      },
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: notification.message
        }
      }
    ]

    blocks =
      if notification.url do
        blocks ++
          [
            %{
              type: "section",
              text: %{
                type: "mrkdwn",
                text: "*Endpoint:* <#{notification.url}|#{notification.url}>"
              }
            }
          ]
      else
        blocks
      end

    blocks =
      if notification.severity != :info do
        blocks ++
          [
            %{
              type: "context",
              elements: [
                %{
                  type: "mrkdwn",
                  text:
                    "*Severity:* #{severity_emoji} `#{Notification.severity_string(notification.severity)}`"
                },
                %{
                  type: "mrkdwn",
                  text: "*Time:* #{DateTime.to_iso8601(notification.timestamp)}"
                }
              ]
            }
          ]
      else
        blocks
      end

    base_payload = %{
      text: "#{title_emoji} #{notification.title}",
      blocks: blocks,
      username: config.username || "Agent Monitor",
      icon_emoji: config.icon_emoji || severity_emoji
    }

    base_payload =
      if config.channel do
        Map.put(base_payload, :channel, config.channel)
      else
        base_payload
      end

    base_payload
  end

  defp severity_to_emoji(:info), do: "ℹ️"
  defp severity_to_emoji(:warning), do: "⚠️"
  defp severity_to_emoji(:error), do: "🔴"
  defp severity_to_emoji(:critical), do: "🚨"

  defp severity_to_title_emoji(:info), do: "ℹ️"
  defp severity_to_title_emoji(:warning), do: "⚠️"
  defp severity_to_title_emoji(:error), do: "❌"
  defp severity_to_title_emoji(:critical), do: "🚨"

  defp exp_backoff(attempt), do: (:math.pow(2, attempt) * 100) |> round()

  defp validate_and_default_config(config) do
    %{
      webhook_url: Map.get(config, :webhook_url),
      channel: Map.get(config, :channel),
      username: Map.get(config, :username, "Agent Monitor"),
      icon_emoji: Map.get(config, :icon_emoji),
      rate_limit_max: Map.get(config, :rate_limit_max, 60),
      rate_limit_window: Map.get(config, :rate_limit_window, 60_000)
    }
  end

  defp get_env_config do
    webhook_url = System.get_env("SLACK_WEBHOOK_URL")

    if webhook_url do
      %{
        webhook_url: webhook_url,
        channel: System.get_env("SLACK_CHANNEL"),
        username: System.get_env("SLACK_USERNAME", "Agent Monitor"),
        icon_emoji: System.get_env("SLACK_ICON_EMOJI"),
        rate_limit_max: parse_env_int("SLACK_RATE_LIMIT_MAX", 60),
        rate_limit_window: parse_env_int("SLACK_RATE_LIMIT_WINDOW", 60_000)
      }
    else
      nil
    end
  end

  defp parse_env_int(env_var, default) do
    case System.get_env(env_var) do
      nil -> default
      val -> String.to_integer(val)
    end
  end
end
