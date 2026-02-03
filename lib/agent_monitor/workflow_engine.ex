defmodule AgentMonitor.WorkflowEngine do
  @moduledoc """
  Orchestrates agent workflows with sequential and parallel execution.
  """

  use GenServer
  require Logger

  alias AgentMonitor.Workflow
  alias AgentMonitor.Conversation
  alias AgentMonitor.ContextVersion
  alias AgentMonitor.ApprovalRequest
  alias AgentMonitor.ParallelExecutor
  alias AgentMonitor.ConversationManager
  alias AgentMonitor.ApprovalWhitelistChecker
  alias AgentMonitor.Incident

  @default_workflow_chain [:monitor_agent, :investigate_agent, :remediate_agent, :verify_agent]
  @workflow_timeout 300_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def execute_workflow(workflow_id) do
    GenServer.call(__MODULE__, {:execute_workflow, workflow_id})
  end

  def get_workflow_status(workflow_id) do
    GenServer.call(__MODULE__, {:get_workflow_status, workflow_id})
  end

  def retry_workflow(workflow_id) do
    GenServer.call(__MODULE__, {:retry_workflow, workflow_id})
  end

  def cancel_workflow(workflow_id) do
    GenServer.call(__MODULE__, {:cancel_workflow, workflow_id})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting WorkflowEngine")
    {:ok, %{active_workflows: %{}}}
  end

  @impl true
  def handle_call({:execute_workflow, workflow_id}, _from, state) do
    workflow = AgentMonitor.Repo.get!(Workflow, workflow_id)

    if workflow.status == :in_progress do
      {:reply, {:error, :already_in_progress}, state}
    else
      AgentMonitor.Repo.update(Workflow.start_changeset(workflow))

      # Start workflow execution in a separate process
      Task.start(fn -> run_workflow(workflow_id) end)

      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:get_workflow_status, workflow_id}, _from, state) do
    workflow = AgentMonitor.Repo.get(Workflow, workflow_id)
    {:reply, workflow, state}
  end

  @impl true
  def handle_call({:retry_workflow, workflow_id}, _from, state) do
    workflow = AgentMonitor.Repo.get(Workflow, workflow_id)

    if Workflow.can_retry?(workflow) do
      AgentMonitor.Repo.update(Workflow.retry_changeset(workflow))

      Task.start(fn ->
        run_workflow_from_step(workflow_id, workflow.failed_step)
      end)

      {:reply, :ok, state}
    else
      {:reply, {:error, :cannot_retry}, state}
    end
  end

  @impl true
  def handle_call({:cancel_workflow, workflow_id}, _from, state) do
    workflow = AgentMonitor.Repo.get(Workflow, workflow_id)

    changeset = Ecto.Changeset.change(workflow, status: :failed)
    AgentMonitor.Repo.update(changeset)

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private Functions

  defp run_workflow(workflow_id) do
    Logger.info("Starting workflow execution: #{workflow_id}")

    workflow = AgentMonitor.Repo.get!(Workflow, workflow_id)

    workflow_chain = get_workflow_chain(workflow)

    case execute_steps(workflow, workflow_chain, 0) do
      {:ok, _result} ->
        AgentMonitor.Repo.update(Workflow.complete_changeset(workflow))
        Logger.info("Workflow completed: #{workflow_id}")

      {:error, reason, step_index} ->
        AgentMonitor.Repo.update(Workflow.fail_changeset(workflow, step_index))
        Logger.error("Workflow failed at step #{step_index}: #{inspect(reason)}")
    end
  end

  defp execute_parallel_branches(workflow, branches, step_index) do
    Logger.info("Executing parallel branches at step #{step_index}")

    case ParallelExecutor.execute_parallel(workflow.id, branches) do
      {:ok, aggregated} ->
        Logger.info(
          "Parallel execution completed: #{aggregated.total_branches} branches, #{aggregated.successful_branches} successful"
        )

        updated_context =
          Map.put(
            workflow.context,
            "parallel_output_step_#{step_index}",
            aggregated.aggregated_output
          )

        AgentMonitor.Repo.update(Workflow.update_context_changeset(workflow, updated_context))

        if aggregated.failed_branches > 0 do
          {:error, :parallel_branch_failure, step_index}
        else
          {:ok, aggregated}
        end

      {:error, reason} ->
        Logger.error("Parallel execution failed: #{inspect(reason)}")
        {:error, reason, step_index}
    end
  end

  defp run_workflow_from_step(workflow_id, step_index) do
    Logger.info("Retrying workflow #{workflow_id} from step #{step_index}")

    workflow = AgentMonitor.Repo.get!(Workflow, workflow_id)
    workflow_chain = get_workflow_chain(workflow)

    remaining_steps = Enum.drop(workflow_chain, step_index)

    case execute_steps(workflow, remaining_steps, step_index) do
      {:ok, _result} ->
        AgentMonitor.Repo.update(Workflow.complete_changeset(workflow))
        Logger.info("Workflow retry completed: #{workflow_id}")

      {:error, reason, failed_step} ->
        AgentMonitor.Repo.update(Workflow.fail_changeset(workflow, failed_step))
        Logger.error("Workflow retry failed at step #{failed_step}: #{inspect(reason)}")
    end
  end

  defp execute_steps(workflow, [], _current_index) do
    {:ok, workflow}
  end

  defp execute_steps(workflow, [agent | rest], current_index) do
    Logger.info("Executing step #{current_index}: #{inspect(agent)}")

    workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)
    AgentMonitor.Repo.update(Workflow.advance_step_changeset(workflow))

    # Check if this step is a parallel branch (list of branches)
    step_result = execute_step(workflow, agent, current_index)

    case step_result do
      {:ok, result} ->
        workflow = AgentMonitor.Repo.get!(Workflow, workflow.id)

        step_data = %{
          index: current_index,
          status: :completed,
          output: result,
          timestamp: DateTime.utc_now()
        }

        # Add agent name or parallel flag
        step_data =
          if is_list(agent) do
            Map.put(step_data, :parallel_branches, length(agent))
          else
            Map.put(step_data, :agent, agent)
          end

        _updated_steps = [step_data | workflow.steps]
        AgentMonitor.Repo.update(Workflow.add_step_changeset(workflow, step_data))

        updated_context = Map.put(workflow.context, "step_#{current_index}_output", result)
        AgentMonitor.Repo.update(Workflow.update_context_changeset(workflow, updated_context))

        # Create context version snapshot
        ContextVersion.create_snapshot(
          workflow.id,
          current_index,
          updated_context,
          to_string(agent)
        )
        |> AgentMonitor.Repo.insert()

        execute_steps(workflow, rest, current_index + 1)

      {:error, reason} ->
        {:error, reason, current_index}
    end
  end

  defp execute_step(workflow, step, step_index) do
    cond do
      # Parallel execution: step is a list of branches
      is_list(step) ->
        execute_parallel_branches(workflow, step, step_index)

      # Sequential execution: step is an atom (agent name)
      is_atom(step) ->
        execute_agent_step(workflow, step, step_index)

      true ->
        {:error, :invalid_step_format}
    end
  end

  defp execute_agent_step(workflow, agent_name, step_index) do
    Logger.info("Executing agent #{inspect(agent_name)} at step #{step_index}")

    context = build_agent_context(workflow, step_index)

    incident_type = get_incident_type(workflow.incident_id)
    risk_level = determine_risk_level(agent_name, context)

    case check_and_request_approval(workflow.id, agent_name, incident_type, risk_level, context) do
      :approved ->
        execute_agent_action(workflow, agent_name, context)

      {:pending, _approval_request} ->
        Logger.info("Approval pending for agent #{agent_name}, waiting...")
        {:error, :approval_pending}

      {:error, reason} ->
        Logger.error("Approval check failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp check_and_request_approval(workflow_id, agent_name, incident_type, risk_level, context) do
    if ApprovalWhitelistChecker.approval_required?(agent_name, incident_type, risk_level) do
      create_approval_request(workflow_id, agent_name, incident_type, risk_level, context)
    else
      :approved
    end
  end

  defp create_approval_request(workflow_id, agent_name, incident_type, risk_level, context) do
    approval_context = %{
      agent_name: to_string(agent_name),
      incident_type: incident_type,
      step_context: context,
      timestamp: DateTime.utc_now()
    }

    changeset =
      ApprovalRequest.create_changeset(
        workflow_id,
        to_string(agent_name),
        "Execute #{agent_name} agent action",
        approval_context,
        risk_level
      )

    case AgentMonitor.Repo.insert(changeset) do
      {:ok, approval_request} ->
        send_approval_notification(approval_request)
        {:pending, approval_request}

      {:error, changeset} ->
        Logger.error("Failed to create approval request: #{inspect(changeset.errors)}")
        {:error, :approval_creation_failed}
    end
  end

  defp execute_agent_action(workflow, agent_name, context) do
    case execute_agent(agent_name, context) do
      {:ok, result} ->
        conversation =
          Conversation.agent_message_changeset(
            workflow.id,
            to_string(agent_name),
            inspect(result)
          )
          |> AgentMonitor.Repo.insert!()

        {:ok, Map.put(result, :conversation_id, conversation.id)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp send_approval_notification(approval_request) do
    Logger.info("Sending approval notification for request #{approval_request.id}")

    severity =
      case approval_request.risk_level do
        :critical -> :critical
        :high -> :error
        :medium -> :warning
        :low -> :info
      end

    notification =
      Notifications.Notification.new(
        title: "Approval Required",
        message: "Action requires approval: #{approval_request.action}",
        severity: severity,
        url: "/approvals/#{approval_request.id}",
        metadata: %{
          approval_id: approval_request.id,
          workflow_id: approval_request.workflow_id,
          agent_id: approval_request.agent_id,
          risk_level: approval_request.risk_level
        }
      )

    Notifications.Dispatcher.send(notification)
  end

  defp determine_risk_level(agent_name, context) do
    case agent_name do
      :remediate_agent ->
        if Map.get(context, :incident_data, %{}) |> Map.get(:severity) == :P1 do
          :critical
        else
          :high
        end

      :investigate_agent ->
        :medium

      :verify_agent ->
        :low

      :monitor_agent ->
        :low

      _ ->
        :medium
    end
  end

  defp get_incident_type(nil), do: "generic"

  defp get_incident_type(incident_id) do
    case AgentMonitor.Repo.get(Incident, incident_id) do
      nil -> "generic"
      _incident -> "generic"
    end
  end

  defp build_agent_context(workflow, step_index) do
    %{
      workflow_id: workflow.id,
      incident_id: workflow.incident_id,
      step_index: step_index,
      previous_outputs: get_previous_outputs(workflow),
      incident_data: get_incident_data(workflow.incident_id),
      system_state: get_system_state(),
      conversation_history: get_conversation_history(workflow.id)
    }
  end

  defp get_workflow_chain(workflow) do
    case workflow.playbook_id do
      nil ->
        @default_workflow_chain

      playbook_id ->
        playbook = AgentMonitor.Repo.get(AgentMonitor.Playbook, playbook_id)

        if playbook,
          do: AgentMonitor.Playbook.get_workflow_chain(playbook),
          else: @default_workflow_chain
    end
  end

  defp get_previous_outputs(workflow) do
    workflow.steps
    |> Enum.filter(fn step -> step[:status] == :completed end)
    |> Enum.map(fn step ->
      {step[:agent], step[:output]}
    end)
    |> Map.new()
  end

  defp get_incident_data(nil), do: nil

  defp get_incident_data(incident_id) do
    case AgentMonitor.Repo.get(AgentMonitor.Incident, incident_id) do
      nil ->
        nil

      incident ->
        %{
          id: incident.id,
          title: incident.title,
          description: incident.description,
          severity: incident.severity,
          status: incident.status
        }
    end
  end

  defp get_system_state do
    uptime_seconds = calculate_uptime()

    %{
      timestamp: DateTime.utc_now(),
      uptime: uptime_seconds,
      memory_usage: :erlang.memory(:total)
    }
  end

  defp calculate_uptime do
    case :erlang.system_info(:start_time) do
      {_, timestamp} -> timestamp
      _start_time -> 0
    end
  end

  defp get_conversation_history(workflow_id) do
    ConversationManager.get_conversation_history(workflow_id)
  end

  defp execute_agent(agent_name, context) do
    agent_module = get_agent_module(agent_name)

    if Code.ensure_loaded?(agent_module) do
      apply(agent_module, :execute, [context])
    else
      Logger.error("Agent module not found: #{agent_name}")
      {:error, :agent_not_found}
    end
  end

  defp get_agent_module(agent_name) do
    case agent_name do
      :monitor_agent -> AgentMonitor.EndpointCheckerAgent
      :investigate_agent -> AgentMonitor.RootCauseAnalysis
      :remediate_agent -> AgentMonitor.Remediation
      :verify_agent -> AgentMonitor.EndpointCheckerAgent
      _ -> Module.concat([AgentMonitor, agent_name])
    end
  end
end
