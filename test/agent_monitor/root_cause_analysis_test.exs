defmodule AgentMonitor.RootCauseAnalysisTest do
  use ExUnit.Case
  alias AgentMonitor.RootCauseAnalysis

  describe "execute/1" do
    test "returns error when no monitor output available" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{},
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:error, :no_monitor_output} = RootCauseAnalysis.execute(context)
    end

    test "performs analysis on error result" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          monitor_agent: %{
            url: "https://example.com",
            last_result: %{
              status: :error,
              reason: "Connection timeout"
            }
          }
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = RootCauseAnalysis.execute(context)
      assert result.agent == :root_cause_analysis
      assert result.status == :analysis_complete
      assert result.url == "https://example.com"
      assert result.error_reason == "Connection timeout"
      assert result.correlation_id != nil
      assert is_binary(result.analysis)
      assert is_list(result.suggested_actions)
      assert length(result.suggested_actions) > 0
    end

    test "returns no_issue when monitor result is ok" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          monitor_agent: %{
            url: "https://example.com",
            last_result: %{
              status: :ok,
              code: 200
            }
          }
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = RootCauseAnalysis.execute(context)
      assert result.status == :no_issue
      assert result.analysis =~ "healthy"
      assert result.suggested_actions == []
    end

    test "handles exception gracefully" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          monitor_agent: nil
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:error, {:exception, _}} = RootCauseAnalysis.execute(context)
    end
  end
end
