defmodule AgentMonitor.VerifyAgent do
  @moduledoc """
  Verification agent for workflow execution.

  This agent verifies that remediation actions were successful
  and that the system is in the expected state.
  """

  require Logger

  @doc """
  Execute verification with the given context.

  ## Parameters
  - context: A map containing:
    - :workflow_id - The workflow ID
    - :incident_id - The incident ID
    - :previous_outputs - Outputs from previous agents
    - :incident_data - Incident information
    - :system_state - Current system state

  ## Returns
  - {:ok, result} - Verification successful
  - {:error, reason} - Verification failed
  """
  def execute(context) do
    Logger.info("VerifyAgent executing for workflow #{context.workflow_id}")

    try do
      previous_outputs = Map.get(context, :previous_outputs, %{})
      remediation_output = Map.get(previous_outputs, :remediate_agent)
      monitor_output = Map.get(previous_outputs, :monitor_agent)

      cond do
        is_nil(remediation_output) ->
          Logger.info("No remediation to verify")
          {:ok, %{status: :skipped, reason: "No remediation performed"}}

        is_nil(monitor_output) ->
          Logger.warning("Cannot verify: no monitor output available")
          {:error, :no_monitor_output}

        true ->
          perform_verification(remediation_output, monitor_output, context)
      end
    rescue
      e ->
        Logger.error("VerifyAgent failed: #{inspect(e)}")
        {:error, {:exception, e}}
    end
  end

  defp perform_verification(remediation_output, monitor_output, _context) do
    url = Map.get(monitor_output, :url)
    remediation_status = Map.get(remediation_output, :status)

    Logger.info("Verifying remediation status: #{remediation_status} for #{url}")

    verification_result = %{
      agent: :verify_agent,
      status: :verification_complete,
      remediation_status: remediation_status,
      url: url,
      verified_at: DateTime.utc_now(),
      checks: [
        check_remediation_outcome(remediation_output),
        check_endpoint_status(monitor_output)
      ]
    }

    {:ok, verification_result}
  end

  defp check_remediation_outcome(remediation_output) do
    status = Map.get(remediation_output, :status, :unknown)

    case status do
      :remediation_attempted ->
        {:passed, "Remediation was attempted"}

      :not_needed ->
        {:skipped, "No remediation needed"}

      _ ->
        {:unknown, "Unknown remediation status"}
    end
  end

  defp check_endpoint_status(monitor_output) do
    status = Map.get(monitor_output, :status, :unknown)

    case status do
      :ok ->
        {:passed, "Endpoint is responding normally"}

      :error ->
        {:failed, "Endpoint is still failing"}

      _ ->
        {:unknown, "Unknown endpoint status"}
    end
  end
end
