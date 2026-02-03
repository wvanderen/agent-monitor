defmodule RemediationE2ETest do
  use ExUnit.Case

  alias Playbooks
  alias Remediation

  setup do
    :ok
  end

  describe "Remediation system" do
    test "check service health for healthy endpoint" do
      result = Remediation.check_service_health("test_service", "https://httpbin.org/status/200")
      assert {:ok, health} = result
      assert health.status == :healthy
      assert is_integer(health.code)
    end

    test "check service health for unhealthy endpoint" do
      result = Remediation.check_service_health("test_service", "https://httpbin.org/status/500")
      assert {:ok, health} = result
      assert health.status == :unhealthy
      assert health.code == 500
    end

    test "queue remediation action" do
      {:ok, id} = Remediation.queue_remediation("test_service", :send_alert, %{message: "Test", severity: :warning})
      assert is_binary(id)
      assert String.starts_with?(id, "rem_")
    end

    test "get remediation history" do
      history = Remediation.get_history(10)
      assert is_list(history)
    end

    test "get queue status" do
      queue = Remediation.get_queue()
      assert is_list(queue)
    end

    test "enable and disable remediation" do
      assert :ok = Remediation.set_enabled(false)
      assert :ok = Remediation.set_enabled(true)
    end
  end

  describe "Playbook system" do
    test "list available playbooks" do
      playbooks = Playbooks.list(5000)
      assert is_list(playbooks)
      assert length(playbooks) > 0
    end

    test "validate playbook structure" do
      valid_playbook = %{id: "test", name: "Test", steps: [%{name: "S1", type: :notify, params: %{}, timeout: 5000, on_failure: :continue, retry_count: 0}], timeout: 30000}
      assert :ok = Playbooks.validate(valid_playbook)
    end

    test "validate invalid playbook returns error" do
      invalid_playbook = %{id: "invalid", name: "Invalid"}
      assert {:error, {:missing_fields, _}} = Playbooks.validate(invalid_playbook)
    end

    test "execute non-existent playbook returns error" do
      result = Playbooks.run("non-existent", %{}, 5000)
      assert {:error, :playbook_not_found} = result
    end
  end

  describe "Playbook steps" do
    test "notify step sends notification" do
      step = %{name: "Test", type: :notify, params: %{title: "Test", message: "Test", severity: :info}, timeout: 5000, on_failure: :continue, retry_count: 0}
      {:ok, result} = Playbooks.execute_step_public(step, %{}, 10000)
      assert result != nil
    end

    test "check step validates endpoint" do
      step = %{name: "Check", type: :check, params: %{url: "https://httpbin.org/status/200"}, timeout: 5000, on_failure: :continue, retry_count: 0}
      {:ok, result} = Playbooks.execute_step_public(step, %{}, 10000)
      assert result.status == :ok
    end

    test "wait step delays execution" do
      step = %{name: "Wait", type: :wait, params: %{duration: 100}, timeout: 1000, on_failure: :continue, retry_count: 0}
      start_time = System.monotonic_time(:millisecond)
      {:ok, result} = Playbooks.execute_step_public(step, %{}, 10000)
      end_time = System.monotonic_time(:millisecond)
      assert result.waited >= 100
      assert end_time - start_time >= 100
    end
  end
end
