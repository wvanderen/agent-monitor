defmodule AgentMonitor.Remediation do
  @moduledoc """
  Remediation agent for workflow execution.

  This agent wraps the Remediation GenServer to provide
  an execute/1 interface compatible with WorkflowEngine.
  """

  require Logger

  @doc """
  Execute remediation actions with the given context.

  ## Parameters
  - context: A map containing:
    - :workflow_id - The workflow ID
    - :incident_id - The incident ID
    - :previous_outputs - Outputs from previous agents
    - :incident_data - Incident information
    - :system_state - Current system state

  ## Returns
  - {:ok, result} - Remediation successful or not needed
  - {:error, reason} - Remediation failed
  """
  def execute(context) do
    Logger.info("Remediation agent executing for workflow #{context.workflow_id}")

    try do
      previous_outputs = Map.get(context, :previous_outputs)

      root_cause_output = Map.get(previous_outputs, :investigate_agent)
      monitor_output = Map.get(previous_outputs, :monitor_agent)

      cond do
        is_nil(root_cause_output) ->
          Logger.error("No root cause analysis available for remediation")
          {:error, :no_root_cause_analysis}

        Map.get(root_cause_output, :status) == :no_issue ->
          Logger.info("No issues found by root cause analysis, remediation not needed")
          {:ok, %{status: :not_needed, reason: "No remediation required"}}

        true ->
          perform_remediation(root_cause_output, monitor_output, context)
      end
    rescue
      e ->
        Logger.error("Remediation failed: #{inspect(e)}")
        {:error, {:exception, e}}
    end
  end

  defp perform_remediation(root_cause_output, monitor_output, _context) do
    Logger.info("Attempting remediation based on root cause analysis")

    url = Map.get(root_cause_output, :url) || Map.get(monitor_output, :url)
    error_reason = Map.get(root_cause_output, :error_reason)

    if is_nil(url) do
      Logger.warning("No URL available for remediation")
      {:error, :no_url_for_remediation}
    else
      remediation_result = %{
        agent: :remediation,
        status: :remediation_attempted,
        url: url,
        action: determine_remediation_action(error_reason),
        outcome: simulate_remediation_action(error_reason),
        suggested_actions: Map.get(root_cause_output, :suggested_actions, []),
        timestamp: DateTime.utc_now()
      }

      {:ok, remediation_result}
    end
  end

  defp determine_remediation_action(error_reason) do
    cond do
      is_nil(error_reason) ->
        :no_action

      String.contains?(to_string(error_reason), "timeout") ->
        :restart_service

      String.contains?(to_string(error_reason), "connection") ->
        :check_network

      String.contains?(to_string(error_reason), "50") ->
        :restart_service

      String.contains?(to_string(error_reason), "40") ->
        :run_playbook

      true ->
        :send_alert
    end
  end

  defp simulate_remediation_action(error_reason) do
    action = determine_remediation_action(error_reason)

    case action do
      :no_action ->
        "No remediation action required"

      :restart_service ->
        "Service restart action would be executed"

      :check_network ->
        "Network connectivity check would be performed"

      :run_playbook ->
        "Recovery playbook would be executed"

      :send_alert ->
        "Alert would be sent to operations team"

      _ ->
        "Generic remediation action"
    end
  end
end
