defmodule IntelligentRoutingE2ETest do
  use ExUnit.Case
  doctest AgentMonitor

  @moduletag :e2e

  setup_all do
    # GenServers are started by the application supervisor
    # We just need to ensure they are running
    Process.sleep(100)
    :ok
  end

  setup do
    # Clear state before each test
    AlertDeduplication.clear_all_alerts()

    :ok
  end

  describe "LLM Router - Intelligent Alert Routing" do
    test "classifies severity for low severity failures (INFO/WARNING)" do
      url = "https://example.com"

      failure_data = %{
        reason: "timeout",
        code: 408,
        duration_ms: 2000,
        consecutive_failures: 1
      }

      {:ok, severity} = LLMRouter.classify_severity(url, failure_data)

      # Low severity alerts should not be critical
      assert severity in [:info, :warning]
    end

    test "classifies severity for critical failures" do
      url = "https://example.com"

      failure_data = %{
        reason: "connection refused",
        code: nil,
        duration_ms: 5000,
        consecutive_failures: 5
      }

      {:ok, severity} = LLMRouter.classify_severity(url, failure_data)

      # High consecutive failures should trigger higher severity
      assert severity in [:error, :critical]
    end

    test "provides recovery suggestions for endpoint failures" do
      url = "https://example.com"

      failure_data = %{
        reason: "timeout",
        code: 408,
        duration_ms: 5000
      }

      {:ok, suggestions} = LLMRouter.get_recovery_suggestions(url, failure_data)

      # Should return a list of suggestions
      assert is_list(suggestions)
      assert length(suggestions) > 0
      assert is_binary(hd(suggestions))
    end

    test "analyzes endpoint health with metrics" do
      url = "https://example.com"

      metrics = %{
        check_count: 10,
        failure_count: 2,
        success_rate: 80.0,
        avg_response_time: 500.0,
        last_check: DateTime.utc_now()
      }

      {:ok, analysis} = LLMRouter.analyze_endpoint(url, metrics)

      # Should return structured analysis
      assert Map.has_key?(analysis, :severity)
      assert Map.has_key?(analysis, :summary)
      assert Map.has_key?(analysis, :suggestions)
      assert is_list(analysis.suggestions)
    end
  end

  describe "Anomaly Detection - Baseline and Learning" do
    test "builds baseline from historical metrics" do
      url = "https://example.com"

      # Record multiple metrics to build baseline
      Enum.each(1..20, fn i ->
        result = %{
          status: :ok,
          duration_ms: 100 + i * 10,
          body_size: 1000,
          code: 200
        }

        AnomalyDetection.record_metric(url, result)
      end)

      # Wait for baseline to be established
      Process.sleep(100)

      baseline = AnomalyDetection.get_baseline(url)

      assert baseline != nil
      assert baseline.url == url
      assert baseline.sample_count >= 10
      assert is_number(baseline.avg_duration_ms)
      assert baseline.success_rate > 0
    end

    test "detects anomalies when response time deviates significantly" do
      url = "https://example.com"

      # Build baseline with normal response times (~100ms)
      Enum.each(1..20, fn i ->
        result = %{
          status: :ok,
          duration_ms: 100 + :rand.uniform(20),
          body_size: 1000,
          code: 200
        }

        AnomalyDetection.record_metric(url, result)
      end)

      Process.sleep(100)

      # Check anomaly with significantly higher response time
      anomalous_result = %{
        status: :ok,
        # 10x normal
        duration_ms: 1000,
        body_size: 1000,
        code: 200
      }

      {:ok, report} = AnomalyDetection.check_anomaly(url, anomalous_result)

      # Should detect anomaly (or report that it checked)
      assert report != nil
      assert report.anomaly_type == :duration
      assert report.url == url
      # The current value is higher than baseline
      assert report.current_value >= report.baseline_value
    end

    test "detects status anomalies with high failure rate" do
      url = "https://example.com"

      # Record mostly successful metrics
      Enum.each(1..15, fn i ->
        result = %{
          status: :ok,
          duration_ms: 100,
          body_size: 1000,
          code: 200
        }

        AnomalyDetection.record_metric(url, result)
      end)

      Process.sleep(100)

      # Record recent failures
      Enum.each(1..8, fn i ->
        result = %{
          status: :error,
          duration_ms: 5000,
          body_size: 0,
          code: 500,
          reason: "internal server error"
        }

        AnomalyDetection.record_metric(url, result)
      end)

      # Check anomaly for latest failure
      failing_result = %{
        status: :error,
        duration_ms: 5000,
        body_size: 0,
        code: 500,
        reason: "internal server error"
      }

      {:ok, report} = AnomalyDetection.check_anomaly(url, failing_result)

      # Should detect an anomaly (either duration or status based on baseline)
      assert report != nil
      # The anomaly type could be :duration or :status depending on baseline statistics
      assert report.anomaly_type in [:duration, :status]
      assert report.url == url
    end
  end

  describe "Root Cause Analysis - Correlation" do
    test "correlates failures across related endpoints" do
      url1 = "https://api.example.com/users"
      url2 = "https://api.example.com/posts"

      # Record correlated failures (same host, similar errors)
      Enum.each(1..5, fn _ ->
        result = %{
          status: :error,
          code: 500,
          duration_ms: 5000,
          reason: "database connection timeout"
        }

        RootCauseAnalysis.record_failure(url1, result)
        RootCauseAnalysis.record_failure(url2, result)
        Process.sleep(10)
      end)

      {:ok, report} = RootCauseAnalysis.analyze_correlations(url1)

      # Should find correlations
      assert report.url == url1
      assert is_list(report.related_endpoints)
      assert length(report.related_endpoints) > 0
      assert url2 in report.related_endpoints
    end

    test "provides root cause hypothesis for failures" do
      url = "https://example.com"

      result = %{
        status: :error,
        code: 503,
        duration_ms: 5000,
        reason: "service unavailable"
      }

      RootCauseAnalysis.record_failure(url, result)

      {:ok, report} = RootCauseAnalysis.find_root_cause(url, result)

      # Should provide analysis
      assert report.url == url
      assert is_binary(report.root_cause_hypothesis)
      assert is_list(report.suggested_actions)
    end

    test "tracks failure patterns over time" do
      url = "https://example.com"

      # Create a failure pattern
      Enum.each(1..10, fn _ ->
        result = %{
          status: :error,
          code: 500,
          duration_ms: 5000,
          reason: "internal server error"
        }

        RootCauseAnalysis.record_failure(url, result)
        Process.sleep(10)
      end)

      patterns = RootCauseAnalysis.get_patterns()

      # Should have recorded patterns
      assert is_list(patterns)
      assert length(patterns) > 0

      pattern = hd(patterns)
      assert Map.has_key?(elem(pattern, 1), :pattern_id)
      assert Map.has_key?(elem(pattern, 1), :affected_endpoints)
    end
  end

  describe "Alert Deduplication - Time Window Logic" do
    test "prevents duplicate alerts within time window" do
      url = "https://example.com"

      result = %{
        status: :error,
        code: 500,
        duration_ms: 5000,
        reason: "internal server error"
      }

      # First alert should be sent
      {:ok, true} = AlertDeduplication.should_send_alert(url, result, :error)

      # Record the alert
      AlertDeduplication.record_alert(url, result, :error)

      # Second alert for same issue should be deduplicated
      {:ok, false} = AlertDeduplication.should_send_alert(url, result, :error)
    end

    test "allows new alerts after time window expires" do
      url = "https://example.com"

      result1 = %{
        status: :error,
        code: 500,
        duration_ms: 5000,
        reason: "internal server error"
      }

      # First alert
      {:ok, true} = AlertDeduplication.should_send_alert(url, result1, :error)
      AlertDeduplication.record_alert(url, result1, :error)

      # Second alert (deduplicated)
      {:ok, false} = AlertDeduplication.should_send_alert(url, result1, :error)

      # New alert with different error type
      result2 = %{
        status: :error,
        code: 404,
        duration_ms: 100,
        reason: "not found"
      }

      # Different error type should be sent
      {:ok, true} = AlertDeduplication.should_send_alert(url, result2, :warning)
    end

    test "provides deduplication statistics" do
      stats = AlertDeduplication.get_stats()

      assert is_map(stats)
      assert Map.has_key?(stats, :sent_count)
      assert Map.has_key?(stats, :deduplicated_count)
      assert Map.has_key?(stats, :time_window_seconds)
      assert Map.has_key?(stats, :cached_alerts)
    end
  end

  describe "Integration - Complete Intelligent Routing Flow" do
    test "low severity alerts are not escalated" do
      url = "https://example.com"

      low_severity_result = %{
        status: :error,
        code: 404,
        duration_ms: 100,
        reason: "not found"
      }

      # Check with alert deduplication
      {:ok, should_send} =
        AlertDeduplication.should_send_alert(url, low_severity_result, :warning)

      # Should allow low severity alerts
      assert should_send == true

      # Record alert
      AlertDeduplication.record_alert(url, low_severity_result, :warning)

      # Try again (should be deduplicated)
      {:ok, should_send_dup} =
        AlertDeduplication.should_send_alert(url, low_severity_result, :warning)

      assert should_send_dup == false
    end

    test "critical alerts are properly escalated" do
      url = "https://example.com"

      critical_result = %{
        status: :error,
        code: nil,
        duration_ms: 5000,
        reason: "connection refused",
        consecutive_failures: 10
      }

      # Classify severity
      {:ok, severity} = LLMRouter.classify_severity(url, critical_result)

      # Critical failures should have high severity
      assert severity in [:error, :critical]

      # Check if alert should be sent
      {:ok, should_send} = AlertDeduplication.should_send_alert(url, critical_result, severity)

      assert should_send == true
    end

    test "anomaly detection flags correct deviations" do
      url = "https://example.com"

      # Build baseline with consistent response times
      Enum.each(1..30, fn i ->
        result = %{
          status: :ok,
          duration_ms: 100 + rem(i, 20),
          body_size: 1000,
          code: 200
        }

        AnomalyDetection.record_metric(url, result)
      end)

      Process.sleep(100)

      # Check baseline
      baseline = AnomalyDetection.get_baseline(url)
      assert baseline != nil

      # Test anomalous response time
      anomalous_result = %{
        status: :ok,
        # Much higher than baseline
        duration_ms: 2000,
        body_size: 1000,
        code: 200
      }

      {:ok, report} = AnomalyDetection.check_anomaly(url, anomalous_result)

      # Should detect anomaly
      assert report != nil
      assert report.anomaly_type == :duration
      assert report.current_value > baseline.avg_duration_ms
    end

    test "root cause analysis correlates failures correctly" do
      url1 = "https://api.example.com/endpoint1"
      url2 = "https://api.example.com/endpoint2"

      # Simulate correlated failures
      Enum.each(1..5, fn _ ->
        result1 = %{
          status: :error,
          code: 503,
          duration_ms: 5000,
          reason: "database timeout"
        }

        result2 = %{
          status: :error,
          code: 503,
          duration_ms: 4800,
          reason: "database timeout"
        }

        RootCauseAnalysis.record_failure(url1, result1)
        RootCauseAnalysis.record_failure(url2, result2)
        Process.sleep(10)
      end)

      # Analyze correlations for first endpoint
      {:ok, report} = RootCauseAnalysis.analyze_correlations(url1)

      # Should correlate failures
      assert url2 in report.related_endpoints
      assert report.likelihood > 0.5
      assert String.contains?(String.downcase(report.root_cause_hypothesis), "correlated")
    end
  end
end
