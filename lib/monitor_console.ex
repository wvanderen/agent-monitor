defmodule Monitor.Console do
  @moduledoc """
  Simple interactive console for the monitor system.

  Run with: iex -S mix
  Then: Monitor.Console.start()
  """

  def start do
    IO.puts("""
    🐱 Agent Monitor Console
    ========================
    Available commands:
    • Monitor.Console.status()       - Show all endpoint status
    • Monitor.Console.add(url)        - Add new endpoint to monitor
    • Monitor.Console.remove(url)     - Remove endpoint
    • Monitor.Console.check(url)      - Trigger immediate check
    • Monitor.Console.list()         - List all monitored endpoints
    • Monitor.Console.history(url)   - Show check history for endpoint
    • Monitor.Console.analyze(url)   - Get AI-powered analysis with recovery suggestions
    """)

    :ok
  end

  def status do
    results = Monitor.Coordinator.get_results()

    if Enum.empty?(results) do
      IO.puts("No endpoints monitored yet.")
    else
      IO.puts("\n📊 Endpoint Status:")
      IO.puts(String.duplicate("=", 60))

      Enum.each(results, fn {url, data} ->
        status = if data.failure_count > 0, do: "🔴 DOWN", else: "🟢 UP"
        last_result = data.last_result

        IO.puts("\n#{status} #{url}")
        IO.puts("   Checks: #{data.check_count} | Failures: #{data.failure_count}")

        if last_result do
          IO.puts(
            "   Last: #{last_result.status} #{if last_result.code, do: "HTTP #{last_result.code}"}"
          )

          reason_text = Map.get(last_result, :reason)

          IO.puts(
            "   Duration: #{last_result.duration_ms}ms #{if reason_text, do: "| #{reason_text}"}"
          )
        end
      end)

      IO.puts("\n" <> String.duplicate("=", 60))
    end

    :ok
  end

  def add(url) do
    case Monitor.Supervisor.add_endpoint(url) do
      {:ok, _pid} ->
        IO.puts("✅ Added endpoint: #{url}")

      {:error, reason} ->
        IO.puts("❌ Failed to add endpoint: #{reason}")
    end

    status()
  end

  def remove(url) do
    case Monitor.Supervisor.remove_endpoint(url) do
      :ok ->
        IO.puts("✅ Removed endpoint: #{url}")

      {:error, :not_found} ->
        IO.puts("❌ Endpoint not found: #{url}")
    end

    status()
  end

  def check(url) do
    # Get the result from coordinator instead
    case Monitor.Coordinator.get_result(url) do
      %{last_check: last_check, last_result: last_result} ->
        IO.puts("Triggering check for #{url}...")
        IO.puts("Previous: #{if last_result, do: last_result.status, else: "no data"}")
        IO.puts("Last check: #{if last_check, do: DateTime.to_string(last_check), else: "never"}")
        IO.puts("\nNew results will be available after the next scheduled check (30s)")

      nil ->
        IO.puts("❌ No data for endpoint: #{url}")
    end

    :ok
  end

  def list do
    endpoints = Monitor.Supervisor.list_endpoints()

    IO.puts("\n📋 Monitored Endpoints:")
    Enum.each(endpoints, fn url -> IO.puts("  • #{url}") end)
    IO.puts("\nTotal: #{length(endpoints)}")

    :ok
  end

  def history(url) do
    case Monitor.Coordinator.get_result(url) do
      nil ->
        IO.puts("❌ No data for endpoint: #{url}")

      %{history: history} ->
        IO.puts("\n📜 Check History for #{url}:")
        IO.puts(String.duplicate("-", 60))

        Enum.with_index(history, fn result, idx ->
          status_icon = if result.status == :ok, do: "✅", else: "❌"
          IO.puts("#{idx + 1}. #{status_icon} #{result.status} - #{result.duration_ms}ms")
          if result.reason, do: IO.puts("   Reason: #{result.reason}")
        end)

        IO.puts(String.duplicate("-", 60))
    end

    :ok
  end

  def analyze(url) do
    case Monitor.Coordinator.get_result(url) do
      nil ->
        IO.puts("❌ No data for endpoint: #{url}")

      endpoint_data ->
        metrics = %{
          url: url,
          check_count: endpoint_data.check_count,
          failure_count: endpoint_data.failure_count,
          success_rate: calculate_success_rate(endpoint_data),
          avg_response_time: calculate_avg_response_time(endpoint_data),
          last_check: endpoint_data.last_check,
          history: endpoint_data.history
        }

        IO.puts("\n🤖 AI-Powered Analysis for #{url}")
        IO.puts(String.duplicate("=", 60))

        case LLMRouter.analyze_endpoint(url, metrics) do
          {:ok, %{severity: severity, summary: summary, suggestions: suggestions}} ->
            severity_str = LLMRouter.Severity.to_string(severity)

            severity_icon =
              case severity do
                :info -> "ℹ️"
                :warning -> "⚠️"
                :error -> "🔴"
                :critical -> "🚨"
              end

            IO.puts("\n#{severity_icon} Severity: #{severity_str}")
            IO.puts("📊 Summary: #{summary}")
            IO.puts("\n💡 Recovery Suggestions:")

            Enum.with_index(suggestions, fn suggestion, idx ->
              IO.puts("  #{idx + 1}. #{suggestion}")
            end)

            IO.puts(String.duplicate("-", 60))
            display_anomaly_detection(url, metrics)
            display_root_cause_analysis(url, endpoint_data.last_result)

          {:error, reason} ->
            IO.puts("❌ Analysis failed: #{inspect(reason)}")
        end

        IO.puts(String.duplicate("=", 60))
    end

    :ok
  end

  defp calculate_success_rate(endpoint_data) do
    if endpoint_data.check_count > 0 do
      success = endpoint_data.check_count - endpoint_data.failure_count
      Float.round(success / endpoint_data.check_count * 100, 1)
    else
      0.0
    end
  end

  defp calculate_avg_response_time(endpoint_data) do
    if endpoint_data.history do
      durations = Enum.map(endpoint_data.history, &Map.get(&1, :duration_ms, 0))

      if length(durations) > 0 do
        Float.round(Enum.sum(durations) / length(durations), 1)
      else
        0.0
      end
    else
      0.0
    end
  end

  defp display_anomaly_detection(url, metrics) do
    case AnomalyDetection.get_baseline(url) do
      nil ->
        IO.puts("📈 Anomaly Detection: Insufficient data for baseline")

      baseline ->
        IO.puts("📈 Anomaly Detection:")

        if metrics.avg_response_time > 0 do
          deviation =
            (metrics.avg_response_time - baseline.avg_duration_ms) / baseline.avg_duration_ms *
              100

          deviation_str =
            if deviation > 0,
              do: "+#{Float.round(deviation, 1)}%",
              else: "#{Float.round(deviation, 1)}%"

          IO.puts(
            "  Current: #{Float.round(metrics.avg_response_time, 1)}ms | Baseline: #{Float.round(baseline.avg_duration_ms, 1)}ms"
          )

          IO.puts("  Deviation: #{deviation_str}")
        end

        IO.puts(
          "  Success Rate: #{Float.round(metrics.success_rate, 1)}% (Baseline: #{Float.round(baseline.success_rate, 1)}%)"
        )

        IO.puts("  Sample Count: #{baseline.sample_count}")
    end
  end

  defp display_root_cause_analysis(url, last_result) do
    IO.puts("\n🔍 Root Cause Analysis:")

    case RootCauseAnalysis.analyze_correlations(url) do
      {:ok, report} ->
        IO.puts(
          "  Related Endpoints: #{if length(report.related_endpoints) > 0, do: inspect(report.related_endpoints), else: "None"}"
        )

        IO.puts("  Likelihood: #{Float.round(report.likelihood * 100, 0)}%")
        IO.puts("  Hypothesis: #{report.root_cause_hypothesis}")

        if length(report.suggested_actions) > 0 do
          IO.puts("  Suggested Actions:")

          Enum.with_index(report.suggested_actions, fn action, idx ->
            IO.puts("    - #{action}")
          end)
        end

      {:error, _reason} ->
        IO.puts("  No correlation data available")
    end
  end
end
