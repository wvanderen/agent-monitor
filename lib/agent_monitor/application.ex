defmodule AgentMonitor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the monitor supervisor with some default endpoints
      {Monitor.Supervisor,
       endpoints: [
         "https://example.com",
         "https://httpbin.org/status/200",
         "https://httpbin.org/delay/1"
       ],
       check_interval: 30_000}
    ]

    opts = [strategy: :one_for_one, name: AgentMonitor.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, _sup} = result ->
        setup_notification_channels()
        result

      error ->
        error
    end
  end

  defp setup_notification_channels do
    # Set up default notification channels with severity-based routing
    defaults = %{
      critical: [:slack, :email],
      error: [:slack, :email],
      warning: [:slack],
      info: []
    }

    Notifications.Dispatcher.set_defaults(defaults)

    # Register Slack channel if configured
    slack_webhook = System.get_env("SLACK_WEBHOOK_URL")

    if slack_webhook do
      Notifications.Dispatcher.register_channel(
        :slack,
        Notifications.Channels.Slack,
        %{webhook_url: slack_webhook},
        enabled: true
      )
    end

    # Register Email channel if configured
    email_from = System.get_env("EMAIL_FROM")
    email_to = System.get_env("EMAIL_TO")

    if email_from && email_to do
      Notifications.Dispatcher.register_channel(
        :email,
        Notifications.Channels.Email,
        %{from: email_from, to: String.split(email_to, ",", trim: true)},
        enabled: true
      )
    end
  end
end
