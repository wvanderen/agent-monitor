defmodule AgentMonitor.ParallelExecutor do
  @moduledoc """
  Executes parallel branches of workflows with isolated contexts.
  """

  use GenServer
  require Logger

  alias AgentMonitor.Workflow
  alias AgentMonitor.Conversation

  @parallel_timeout 120_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def execute_parallel(workflow_id, branches) do
    GenServer.call(__MODULE__, {:execute_parallel, workflow_id, branches}, @parallel_timeout)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting ParallelExecutor")
    {:ok, %{active_tasks: %{}}}
  end

  @impl true
  def handle_call({:execute_parallel, workflow_id, branches}, _from, state) do
    Logger.info("Executing parallel branches for workflow #{workflow_id}")

    workflow = AgentMonitor.Repo.get!(Workflow, workflow_id)

    # Create isolated contexts for each branch
    base_context = build_base_context(workflow)

    branch_tasks =
      Enum.map(branches, fn branch ->
        Task.Supervisor.async_nolink(
          AgentMonitor.TaskSupervisor,
          fn -> execute_branch(workflow_id, branch, base_context) end
        )
      end)

    # Wait for all branches to complete
    results =
      Enum.map(branch_tasks, fn task ->
        Task.await(task, @parallel_timeout)
      end)

    # Aggregate results
    aggregated = aggregate_results(results)

    {:reply, {:ok, aggregated}, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private Functions

  defp execute_branch(workflow_id, branch, base_context) do
    Logger.info("Executing branch: #{inspect(branch)}")

    branch_context = create_isolated_context(base_context, branch)

    try do
      results =
        Enum.map(branch.agents, fn agent ->
          execute_agent_in_branch(workflow_id, agent, branch_context)
        end)

      {:ok, %{branch: branch.name, results: results}}
    rescue
      e ->
        Logger.error("Branch execution failed: #{inspect(e)}")
        {:error, %{branch: branch.name, error: Exception.message(e)}}
    end
  end

  defp create_isolated_context(base_context, branch) do
    Map.merge(base_context, %{
      branch_name: branch.name,
      branch_variables: branch.variables || %{}
    })
  end

  defp execute_agent_in_branch(workflow_id, agent_name, context) do
    Logger.info("Executing agent #{agent_name} in parallel branch")

    agent_module = get_agent_module(agent_name)

    if Code.ensure_loaded?(agent_module) do
      case apply(agent_module, :execute, [context]) do
        {:ok, result} ->
          # Add conversation entry for this agent
          Conversation.agent_message_changeset(
            workflow_id,
            to_string(agent_name),
            inspect(result)
          )
          |> AgentMonitor.Repo.insert!()

          {:ok, %{agent: agent_name, result: result}}

        {:error, reason} ->
          {:error, %{agent: agent_name, reason: reason}}
      end
    else
      Logger.warning("Agent module not found: #{agent_name}")
      {:error, %{agent: agent_name, reason: "Module not found"}}
    end
  end

  defp aggregate_results(results) do
    successful = Enum.filter(results, fn {status, _} -> status == :ok end)
    failed = Enum.filter(results, fn {status, _} -> status == :error end)

    %{
      total_branches: length(results),
      successful_branches: length(successful),
      failed_branches: length(failed),
      results: results,
      aggregated_output: merge_successful_outputs(successful)
    }
  end

  defp merge_successful_outputs(successful_results) do
    Enum.reduce(successful_results, %{}, fn {:ok, data}, acc ->
      Enum.reduce(data.results, acc, fn {:ok, agent_result}, inner_acc ->
        Map.put(inner_acc, agent_result.agent, agent_result.result)
      end)
    end)
  end

  defp build_base_context(workflow) do
    %{
      workflow_id: workflow.id,
      incident_id: workflow.incident_id,
      workflow_context: workflow.context
    }
  end

  defp get_agent_module(agent_name) do
    case agent_name do
      :investigate_logs -> AgentMonitor.RootCauseAnalysis
      :investigate_metrics -> AgentMonitor.AnomalyDetection
      :investigate_dependencies -> AgentMonitor.Remediation
      _ -> Module.concat([AgentMonitor, agent_name])
    end
  end
end
