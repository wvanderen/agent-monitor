#!/usr/bin/env elixir

defmodule CLI do
  @moduledoc """
  Command-line interface for Agent Monitor.

  Usage:
    mix run cli.exs [command] [options]

  Commands:
    status       Show all endpoint status
    add <url>    Add a new endpoint to monitor
    remove <url> Remove an endpoint
    check <url>  Trigger immediate check for an endpoint
    list         List all monitored endpoints
    history <url>Show check history for endpoint
    watch        Continuously show status (updates every 5s)
  """

  def main(args) do
    Application.put_env(:agent_monitor, :coordinator, Monitor.Coordinator)

    case args do
      [] ->
        show_help()

      ["status"] ->
        Mix.Task.run("run", ["-e", "Monitor.Console.status()"])

      ["add", url] ->
        Mix.Task.run("run", ["-e", "Monitor.Console.add(\"#{url}\")"])

      ["remove", url] ->
        Mix.Task.run("run", ["-e", "Monitor.Console.remove(\"#{url}\")"])

      ["check", url] ->
        Mix.Task.run("run", ["-e", "Monitor.Console.check(\"#{url}\")"])

      ["list"] ->
        Mix.Task.run("run", ["-e", "Monitor.Console.list()"])

      ["history", url] ->
        Mix.Task.run("run", ["-e", "Monitor.Console.history(\"#{url}\")"])

      ["watch"] ->
        watch_mode()

      _ ->
        IO.puts("Unknown command: #{Enum.join(args, " ")}\n")
        show_help()
    end
  end

  defp show_help do
    IO.puts("""
    🐱 Agent Monitor CLI
    ===================

    Usage: mix run cli.exs [command] [options]

    Commands:
      status              Show all endpoint status
      add <url>           Add a new endpoint
      remove <url>        Remove an endpoint
      check <url>         Trigger immediate check
      list                List all endpoints
      history <url>       Show check history
      watch               Live status updates (every 5s)

    Examples:
      mix run cli.exs status
      mix run cli.exs add https://api.github.com
      mix run cli.exs watch
    """)
  end

  defp watch_mode do
    IO.puts("👀 Watching endpoints (press Ctrl+C to exit)...")
    IO.puts(String.duplicate("=", 60))

    Stream.repeatedly(fn ->
      Mix.Task.run("run", ["-e", "Monitor.Console.status()", "--no-start"])
      IO.puts("\n")
      Process.sleep(5000)
    end)
    |> Stream.run()
  end
end

# Run the CLI
CLI.main(System.argv())
