defmodule AgentMonitor.Application do
  use Application

  def start(_type, _args) do
    children = [
      AgentMonitor.Repo,
      {Phoenix.PubSub, name: AgentMonitor.PubSub},
      AgentMonitorWeb.Endpoint,
      AgentMonitor.TaskSupervisor,
      AgentMonitor.WorkflowEngine,
      AgentMonitor.ParallelExecutor,
      AgentMonitor.ConversationManager,
      AgentMonitor.UptimeCollector,
      AgentMonitor.ApprovalWhitelistChecker,
      AgentMonitor.ApprovalExpiryChecker,
      {Monitor.Supervisor,
       endpoints: [
         "https://example.com",
         "https://httpbin.org/status/200",
         "https://httpbin.org/delay/1"
       ],
       check_interval: 30_000}
    ]

    opts = [strategy: :one_for_one, name: AgentMonitor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    AgentMonitorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
