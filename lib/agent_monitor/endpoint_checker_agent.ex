defmodule AgentMonitor.EndpointCheckerAgent do
  @moduledoc """
  Endpoint checker agent for workflow execution.

  This agent wraps the Monitor.EndpointChecker GenServer to provide
  an execute/1 interface compatible with WorkflowEngine.
  """

  require Logger

  @doc """
  Execute endpoint check with the given context.

  ## Parameters
  - context: A map containing:
    - :workflow_id - The workflow ID
    - :incident_id - The incident ID
    - :incident_data - Incident information
    - :system_state - Current system state

  ## Returns
  - {:ok, result} - Check completed
  - {:error, reason} - Check failed
  """
  def execute(context) do
    Logger.info("EndpointChecker agent executing for workflow #{context.workflow_id}")

    try do
      incident_data = Map.get(context, :incident_data)

      url = extract_url(incident_data)

      if is_nil(url) do
        Logger.warning("No URL found for endpoint check")
        {:error, :no_url}
      else
        perform_endpoint_check(url, context)
      end
    rescue
      e ->
        Logger.error("EndpointChecker failed: #{inspect(e)}")
        {:error, {:exception, e}}
    end
  end

  defp extract_url(nil), do: nil

  defp extract_url(%{description: desc}) when is_binary(desc) do
    case Regex.run(~r/https?:\/\/[^\s]+/, desc) do
      [url | _] -> url
      nil -> nil
    end
  end

  defp extract_url(_), do: nil

  defp perform_endpoint_check(url, context) do
    Logger.debug("Checking endpoint: #{url}")

    start_time = System.monotonic_time(:millisecond)

    result =
      case HTTPoison.get(url, [], follow_redirect: true, timeout: 5000) do
        {:ok, %{status_code: code, body: body, headers: headers}} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          if code >= 200 and code < 300 do
            %{
              status: :ok,
              code: code,
              duration_ms: duration,
              body_size: byte_size(body),
              headers: headers
            }
          else
            %{
              status: :error,
              code: code,
              duration_ms: duration,
              reason: "HTTP #{code}"
            }
          end

        {:error, %{reason: reason}} ->
          end_time = System.monotonic_time(:millisecond)
          duration = end_time - start_time

          %{
            status: :error,
            code: nil,
            duration_ms: duration,
            reason: inspect(reason)
          }
      end

    check_result = %{
      agent: :endpoint_checker,
      url: url,
      last_result: result,
      timestamp: DateTime.utc_now(),
      workflow_id: context.workflow_id,
      incident_id: context.incident_id
    }

    {:ok, check_result}
  end
end
