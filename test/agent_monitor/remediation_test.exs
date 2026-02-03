defmodule AgentMonitor.RemediationTest do
  use ExUnit.Case
  alias AgentMonitor.Remediation

  describe "execute/1" do
    test "returns skipped when no root cause output available" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{},
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = Remediation.execute(context)
      assert result.status == :skipped
      assert result.reason == "No root cause analysis available"
    end

    test "returns not_needed when no issues found" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          monitor_agent: %{url: "https://example.com"},
          investigate_agent: %{
            status: :no_issue,
            url: "https://example.com"
          }
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = Remediation.execute(context)
      assert result.status == :not_needed
      assert result.reason == "No remediation required"
    end

    test "performs remediation for timeout error" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          monitor_agent: %{url: "https://example.com"},
          investigate_agent: %{
            status: :analysis_complete,
            url: "https://example.com",
            error_reason: "Connection timeout",
            suggested_actions: ["Restart service", "Check logs"]
          }
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = Remediation.execute(context)
      assert result.agent == :remediation
      assert result.status == :remediation_attempted
      assert result.url == "https://example.com"
      assert result.action == :restart_service
      assert is_binary(result.outcome)
      assert result.suggested_actions == ["Restart service", "Check logs"]
    end

    test "determines correct action for connection error" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          monitor_agent: %{url: "https://example.com"},
          investigate_agent: %{
            status: :analysis_complete,
            url: "https://example.com",
            error_reason: "Connection refused"
          }
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = Remediation.execute(context)
      assert result.action == :check_network
    end

    test "determines correct action for 50x error" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          monitor_agent: %{url: "https://example.com"},
          investigate_agent: %{
            status: :analysis_complete,
            url: "https://example.com",
            error_reason: "HTTP 500"
          }
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = Remediation.execute(context)
      assert result.action == :restart_service
    end

    test "determines correct action for 40x error" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          monitor_agent: %{url: "https://example.com"},
          investigate_agent: %{
            status: :analysis_complete,
            url: "https://example.com",
            error_reason: "HTTP 404"
          }
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = Remediation.execute(context)
      assert result.action == :run_playbook
    end

    test "handles exception gracefully" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        previous_outputs: %{
          investigate_agent: nil
        },
        incident_data: %{title: "Test Incident"},
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:error, {:exception, _}} = Remediation.execute(context)
    end
  end
end
