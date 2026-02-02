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
       check_interval: 30_000  # 30 seconds
      }
    ]

    opts = [strategy: :one_for_one, name: AgentMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
