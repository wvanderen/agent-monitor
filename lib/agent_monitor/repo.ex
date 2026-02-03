defmodule AgentMonitor.Repo do
  use Ecto.Repo,
    otp_app: :agent_monitor,
    adapter: Ecto.Adapters.Postgres
end
