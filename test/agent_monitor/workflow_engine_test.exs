defmodule AgentMonitor.WorkflowEngineTest do
  use AgentMonitor.DataCase
  alias AgentMonitor.Workflow
  alias AgentMonitor.WorkflowEngine
  alias AgentMonitor.Incident

  setup do
    {:ok, pid} = WorkflowEngine.start_link([])
    %{pid: pid}
  end

  describe "workflow execution" do
    test "execute_workflow/1 starts a new workflow" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      assert :ok = WorkflowEngine.execute_workflow(workflow.id)

      Process.sleep(100)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)
      assert updated_workflow.status in [:in_progress, :completed, :failed]
    end

    test "execute_workflow/1 returns error if already in progress" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :in_progress
        })
        |> AgentMonitor.Repo.insert()

      assert {:error, :already_in_progress} = WorkflowEngine.execute_workflow(workflow.id)
    end

    test "execute_workflow/1 creates context versions for each step" do
      incident = insert(:incident, description: "Test incident https://example.com/test")

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(2000)

      context_versions =
        AgentMonitor.Repo.all(
          from(cv in AgentMonitor.ContextVersion, where: cv.workflow_id == ^workflow.id)
        )

      assert length(context_versions) > 0
    end
  end

  describe "workflow status" do
    test "get_workflow_status/1 returns the workflow" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      assert %Workflow{id: id} = WorkflowEngine.get_workflow_status(workflow.id)
      assert id == workflow.id
    end
  end

  describe "workflow retry" do
    test "retry_workflow/1 retries from failed step" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :failed,
          failed_step: 1,
          retry_count: 0
        })
        |> AgentMonitor.Repo.insert()

      assert :ok = WorkflowEngine.retry_workflow(workflow.id)

      Process.sleep(100)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)
      assert updated_workflow.retry_count > 0
      assert updated_workflow.status == :in_progress
    end

    test "retry_workflow/1 returns error if cannot retry" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :completed,
          failed_step: nil,
          retry_count: 0
        })
        |> AgentMonitor.Repo.insert()

      assert {:error, :cannot_retry} = WorkflowEngine.retry_workflow(workflow.id)
    end

    test "retry_workflow/1 respects max_retries limit" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :failed,
          failed_step: 1,
          retry_count: 3,
          max_retries: 3
        })
        |> AgentMonitor.Repo.insert()

      assert {:error, :cannot_retry} = WorkflowEngine.retry_workflow(workflow.id)
    end
  end

  describe "workflow cancellation" do
    test "cancel_workflow/1 sets status to failed" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      assert :ok = WorkflowEngine.cancel_workflow(workflow.id)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)
      assert updated_workflow.status == :failed
    end
  end

  defp insert(:incident, attrs \\ %{}) do
    default_attrs = %{
      title: "Test Incident",
      description: "Test incident description",
      severity: :P3,
      status: :open
    }

    final_attrs = Map.merge(default_attrs, attrs)

    {:ok, incident} =
      Incident.changeset(%Incident{}, final_attrs)
      |> AgentMonitor.Repo.insert()

    incident
  end
end
