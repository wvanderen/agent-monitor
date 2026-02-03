import Config

config :agent_monitor,
  ecto_repos: [AgentMonitor.Repo]

config :agent_monitor, AgentMonitor.Repo,
  username: "postgres",
  password: "postgres",
  database: "agent_monitor_dev",
  hostname: "localhost",
  pool_size: 10

config :agent_monitor, AgentMonitorWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "super_secret_key_change_in_production",
  render_errors: [view: AgentMonitorWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: AgentMonitor.PubSub,
  live_view: [signing_salt: "signing_salt_change_in_production"]

config :esbuild,
  version: "0.20.1",
  default: [
    args: ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.0",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :agent_monitor, AgentMonitor.Mailer, adapter: Swoosh.Adapters.Local

config :logger,
  backends: [:console],
  compile_time_purge_matching: [
    [level_lower_than: :info]
  ]

import_config "#{config_env()}.exs"
