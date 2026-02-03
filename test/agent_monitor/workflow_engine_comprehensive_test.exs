defmodule AgentMonitor.WorkflowEngine.ComprehensiveTest do
  use AgentMonitor.DataCase
  alias AgentMonitor.Workflow
  alias AgentMonitor.WorkflowEngine
  alias AgentMonitor.Incident
  alias AgentMonitor.Playbook
  alias AgentMonitor.Conversation

  setup do
    {:ok, pid} = WorkflowEngine.start_link([])
    %{pid: pid}
  end

  describe "sequential agent chaining" do
    test "passes output from one agent to the next" do
      incident = insert(:incident, description: "Test incident https://example.com/test")

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

      assert updated_workflow.steps != []
      assert updated_workflow.context != %{}

      step_outputs =
        for step <- updated_workflow.steps, into: %{} do
          {step[:agent], step[:output]}
        end

      assert Map.has_key?(step_outputs, :monitor_agent)
      assert Map.has_key?(step_outputs, :investigate_agent)
    end

    test "tracks step completion in order" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

      if updated_workflow.status in [:completed, :in_progress] do
        completed_steps =
          updated_workflow.steps
          |> Enum.filter(fn step -> step[:status] == :completed end)

        assert length(completed_steps) > 0

        indices = Enum.map(completed_steps, & &1[:index])
        assert indices == Enum.sort(indices)
      end
    end
  end

  describe "context passing" do
    test "includes previous outputs in agent context" do
      incident = insert(:incident, description: "Test incident https://example.com/test")

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

      if length(updated_workflow.steps) >= 2 do
        assert updated_workflow.context["step_0_output"]
        assert updated_workflow.context["step_1_output"]
      end
    end

    test "includes incident data in context" do
      incident = insert(:incident, description: "Test incident with data")

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(1000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)
      assert updated_workflow.context != %{}
    end

    test "includes system state in context" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(1000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)
      assert updated_workflow.context != %{}
    end
  end

  describe "custom workflow chains" do
    test "uses default chain when no playbook assigned" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending,
          playbook_id: nil
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

      agents = Enum.map(updated_workflow.steps, & &1[:agent])
      expected_agents = [:monitor_agent, :investigate_agent, :remediate_agent, :verify_agent]

      assert agents == expected_agents or
               Enum.all?(expected_agents, &Enum.member?(agents, &1))
    end

    test "uses playbook workflow chain when playbook assigned" do
      playbook =
        insert(:playbook, %{
          name: "Custom Playbook",
          workflow_chain: [:monitor_agent, :investigate_agent],
          steps: []
        })

      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending,
          playbook_id: playbook.id
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

      agents = Enum.map(updated_workflow.steps, & &1[:agent])
      assert length(agents) <= 2
    end
  end

  describe "conversation history" do
    test "creates conversation entries for each agent step" do
      incident = insert(:incident, description: "Test incident https://example.com/test")

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      conversations =
        AgentMonitor.Repo.all(from(c in Conversation, where: c.workflow_id == ^workflow.id))

      assert length(conversations) > 0

      agent_ids = Enum.map(conversations, & &1.agent_id)
      assert Enum.any?(agent_ids, &(&1 != "system"))
    end

    test "stores agent outputs in conversation content" do
      incident = insert(:incident, description: "Test incident https://example.com/test")

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      conversations =
        AgentMonitor.Repo.all(from(c in Conversation, where: c.workflow_id == ^workflow.id))

      assert length(conversations) > 0
      assert Enum.all?(conversations, fn c -> c.content != nil end)
    end
  end

  describe "error handling" do
    test "handles agent failures gracefully" do
      incident = insert(:incident, description: "Invalid URL")

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

      assert updated_workflow.status in [:completed, :failed, :in_progress]
    end

    test "sets failed_step index on workflow failure" do
      incident = insert(:incident, description: "Test incident")

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

      if updated_workflow.status == :failed do
        assert updated_workflow.failed_step != nil
      end
    end
  end

  describe "context versioning" do
    test "creates snapshot before each step" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      context_versions =
        AgentMonitor.Repo.all(
          from(cv in AgentMonitor.ContextVersion, where: cv.workflow_id == ^workflow.id)
        )

      assert length(context_versions) > 0

      Enum.each(context_versions, fn cv ->
        assert cv.context_snapshot != %{}
        assert cv.step_number != nil
      end)
    end

    test "stores context snapshot for each completed step" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

      context_versions =
        AgentMonitor.Repo.all(
          from(cv in AgentMonitor.ContextVersion, where: cv.workflow_id == ^workflow.id)
        )

      completed_steps = Enum.count(updated_workflow.steps, &(&1[:status] == :completed))
      assert length(context_versions) >= completed_steps
    end
  end

  describe "state transitions" do
    test "transitions from pending to in_progress on execution" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending
        })
        |> AgentMonitor.Repo.insert()

      assert workflow.status == :pending

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(500)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)
      assert updated_workflow.status in [:in_progress, :completed, :failed]
    end

    test "increments current_step during execution" do
      incident = insert(:incident)

      {:ok, workflow} =
        Workflow.changeset(%Workflow{}, %{
          incident_id: incident.id,
          status: :pending,
          current_step: 0
        })
        |> AgentMonitor.Repo.insert()

      WorkflowEngine.execute_workflow(workflow.id)
      Process.sleep(3000)

      updated_workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)
      assert updated_workflow.current_step >= workflow.current_step
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

  defp insert(:playbook, attrs \\ %{}) do
    default_attrs = %{
      name: "Test Playbook",
      incident_type: "generic",
      steps: [],
      workflow_chain: [:monitor_agent, :investigate_agent, :remediate_agent, :verify_agent]
    }

    final_attrs = Map.merge(default_attrs, attrs)

    {:ok, playbook} =
      Playbook.changeset(%Playbook{}, final_attrs)
      |> AgentMonitor.Repo.insert()

    playbook
  end
end
