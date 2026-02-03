defmodule AgentMonitor.RootCauseAnalysis do
  @moduledoc """
  Root Cause Analysis agent for workflow execution.

  This agent wraps the RootCauseAnalysis GenServer to provide
  an execute/1 interface compatible with WorkflowEngine.
  """

  require Logger

  @doc """
  Execute root cause analysis with the given context.

  ## Parameters
  - context: A map containing:
    - :workflow_id - The workflow ID
    - :incident_id - The incident ID
    - :previous_outputs - Outputs from previous agents
    - :incident_data - Incident information
    - :system_state - Current system state

  ## Returns
  - {:ok, result} - Analysis successful
  - {:error, reason} - Analysis failed
  """
  def execute(context) do
    Logger.info("RootCauseAnalysis agent executing for workflow #{context.workflow_id}")

    try do
      incident_data = Map.get(context, :incident_data)
      previous_outputs = Map.get(context, :previous_outputs)

      monitor_output = Map.get(previous_outputs, :monitor_agent)

      cond do
        is_nil(monitor_output) ->
          Logger.warning("No monitor output available for root cause analysis")
          {:error, :no_monitor_output}

        true ->
          url = Map.get(monitor_output, :url) || get_url_from_context(context)
          result = Map.get(monitor_output, :last_result)

          if is_nil(url) or is_nil(result) do
            Logger.warning("Incomplete monitor data for root cause analysis")
            {:error, :incomplete_monitor_data}
          else
            perform_analysis(url, result, context)
          end
      end
    rescue
      e ->
        Logger.error("RootCauseAnalysis failed: #{inspect(e)}")
        {:error, {:exception, e}}
    end
  end

  defp get_url_from_context(context) do
    case Map.get(context, :incident_data) do
      %{description: desc} when is_binary(desc) ->
        extract_url_from_description(desc)

      _ ->
        nil
    end
  end

  defp extract_url_from_description(description) do
    case Regex.run(~r/https?:\/\/[^\s]+/, description) do
      [url | _] -> url
      nil -> nil
    end
  end

  defp perform_analysis(url, result, context) do
    Logger.debug("Analyzing root cause for #{url}")

    correlation_id =
      if Map.get(result, :status) == :error do
        generate_correlation_id()
      else
        nil
      end

    analysis_result = %{
      agent: :root_cause_analysis,
      status: if(result.status == :error, do: :analysis_complete, else: :no_issue),
      url: url,
      error_reason: Map.get(result, :reason),
      correlation_id: correlation_id,
      analysis: generate_analysis(result, context),
      suggested_actions: generate_actions(result),
      timestamp: DateTime.utc_now()
    }

    {:ok, analysis_result}
  end

  defp generate_analysis(result, _context) do
    case result do
      %{status: :error, reason: reason} ->
        "Root cause analysis indicates: #{reason}"

      %{status: :ok} ->
        "Endpoint is healthy, no root cause analysis needed"

      _ ->
        "Unable to determine root cause"
    end
  end

  defp generate_actions(result) do
    case result do
      %{status: :error} ->
        [
          "Review server logs for detailed error information",
          "Check network connectivity and firewall rules",
          "Verify service dependencies are available",
          "Consider increasing resource allocation if needed"
        ]

      _ ->
        []
    end
  end

  defp generate_correlation_id do
    :crypto.strong_rand_bytes(8)
    |> Base.encode16(case: :lower)
  end
end
