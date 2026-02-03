defmodule AgentMonitor.MixProject do
  use Mix.Project

  def project do
    [
      app: :agent_monitor,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind agent_monitor", "esbuild agent_monitor"],
      "assets.deploy": [
        "tailwind agent_monitor --minify",
        "esbuild agent_monitor --minify",
        "phx.digest"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {AgentMonitor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:httpoison, "~> 2.2"},
      {:jason, "~> 1.4"},
      {:swoosh, "~> 1.16"},
      {:gen_smtp, "~> 1.0"},
      {:yamerl, "~> 0.10"},
      {:hackney, "~> 1.20"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"}
    ]
  end
end
