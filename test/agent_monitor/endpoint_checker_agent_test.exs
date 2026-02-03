defmodule AgentMonitor.EndpointCheckerAgentTest do
  use ExUnit.Case
  alias AgentMonitor.EndpointCheckerAgent

  describe "execute/1" do
    test "returns error when no URL available" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        incident_data: nil,
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:error, :no_url} = EndpointCheckerAgent.execute(context)
    end

    test "extracts URL from incident description" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        incident_data: %{
          title: "Test Incident",
          description: "Service down at https://httpbin.org/status/500"
        },
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = EndpointCheckerAgent.execute(context)
      assert result.agent == :endpoint_checker
      assert result.url == "https://httpbin.org/status/500"
      assert is_map(result.last_result)
    end

    test "handles successful HTTP response" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        incident_data: %{
          description: "Check https://httpbin.org/status/200"
        },
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = EndpointCheckerAgent.execute(context)
      assert result.last_result.status == :ok
      assert result.last_result.code == 200
      assert result.last_result.duration_ms > 0
    end

    test "handles HTTP error response" do
      context = %{
        workflow_id: Ecto.UUID.generate(),
        incident_id: Ecto.UUID.generate(),
        incident_data: %{
          description: "Check https://httpbin.org/status/500"
        },
        system_state: %{timestamp: DateTime.utc_now()}
      }

      assert {:ok, result} = EndpointCheckerAgent.execute(context)
      assert result.last_result.status == :error
      assert result.last_result.code == 500
      assert result.last_result.reason == "HTTP 500"
    end
  end
end
