import Config

database_url = System.get_env("DATABASE_URL")

config :agent_monitor, AgentMonitor.Repo,
  url: database_url || "postgres://postgres:postgres@localhost/agent_monitor_prod",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :agent_monitor, AgentMonitorWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info
