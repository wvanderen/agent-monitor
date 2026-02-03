defmodule AgentMonitor.WorkflowTest do
  use ExUnit.Case
  alias AgentMonitor.Workflow

  describe "Workflow schema" do
    test "changeset with valid attributes" do
      attrs = %{
        incident_id: Ecto.UUID.generate(),
        status: :pending,
        current_step: 0,
        steps: [],
        context: %{},
        retry_count: 0,
        max_retries: 3
      }

      changeset = Workflow.changeset(%Workflow{}, attrs)

      assert changeset.valid?
    end

    test "changeset requires incident_id" do
      attrs = %{
        status: :pending
      }

      changeset = Workflow.changeset(%Workflow{}, attrs)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :incident_id)
    end

    test "changeset validates current_step is non-negative" do
      attrs = %{
        incident_id: Ecto.UUID.generate(),
        current_step: -1
      }

      changeset = Workflow.changeset(%Workflow{}, attrs)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :current_step)
    end

    test "changeset validates retry_count is non-negative" do
      attrs = %{
        incident_id: Ecto.UUID.generate(),
        retry_count: -1
      }

      changeset = Workflow.changeset(%Workflow{}, attrs)

      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :retry_count)
    end

    test "start_changeset sets status to in_progress and current_step to 0" do
      workflow = %Workflow{status: :pending, current_step: 5}
      changeset = Workflow.start_changeset(workflow)

      assert changeset.changes[:status] == :in_progress
      assert changeset.changes[:current_step] == 0
    end

    test "complete_changeset sets status to completed" do
      workflow = %Workflow{status: :in_progress}
      changeset = Workflow.complete_changeset(workflow)

      assert changeset.changes[:status] == :completed
    end

    test "fail_changeset sets status to failed and failed_step" do
      workflow = %Workflow{status: :in_progress}
      changeset = Workflow.fail_changeset(workflow, 2)

      assert changeset.changes[:status] == :failed
      assert changeset.changes[:failed_step] == 2
    end

    test "advance_step_changeset increments current_step" do
      workflow = %Workflow{current_step: 2}
      changeset = Workflow.advance_step_changeset(workflow)

      assert changeset.changes[:current_step] == 3
    end

    test "update_context_changeset merges new context" do
      workflow = %Workflow{context: %{existing_key: "value"}}
      new_context = %{new_key: "new_value"}
      changeset = Workflow.update_context_changeset(workflow, new_context)

      expected_context = %{
        existing_key: "value",
        new_key: "new_value"
      }

      assert changeset.changes[:context] == expected_context
    end

    test "add_step_changeset appends step to steps" do
      workflow = %Workflow{steps: [%{step: 1}]}
      step_data = %{step: 2, agent: :test_agent}
      changeset = Workflow.add_step_changeset(workflow, step_data)

      assert length(changeset.changes[:steps]) == 2
      assert List.last(changeset.changes[:steps]) == step_data
    end

    test "retry_changeset increments retry_count and sets status to in_progress" do
      workflow = %Workflow{status: :failed, retry_count: 0}
      changeset = Workflow.retry_changeset(workflow)

      assert changeset.changes[:status] == :in_progress
      assert changeset.changes[:retry_count] == 1
    end

    test "can_retry? returns true for failed workflow within retry limit" do
      workflow = %Workflow{
        status: :failed,
        retry_count: 2,
        max_retries: 3
      }

      assert Workflow.can_retry?(workflow)
    end

    test "can_retry? returns false for completed workflow" do
      workflow = %Workflow{
        status: :completed,
        retry_count: 0,
        max_retries: 3
      }

      refute Workflow.can_retry?(workflow)
    end

    test "can_retry? returns false when retry count exceeded" do
      workflow = %Workflow{
        status: :failed,
        retry_count: 3,
        max_retries: 3
      }

      refute Workflow.can_retry?(workflow)
    end
  end
end
