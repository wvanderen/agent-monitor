import Config

config :agent_monitor, AgentMonitor.Repo,
  username: "postgres",
  password: "postgres",
  database: "agent_monitor_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :agent_monitor, AgentMonitorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_change_this",
  server: false

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
