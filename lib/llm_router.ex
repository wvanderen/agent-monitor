defmodule LLMRouter do
  @moduledoc """
  LLM Router Service for intelligent alert routing and analysis.

  Integrates with Claude AI to classify alert severity, provide recovery suggestions,
  and perform intelligent analysis of endpoint failures.
  """

  use GenServer
  require Logger

  defmodule Config do
    @moduledoc """
    Configuration for LLM router.
    """
    defstruct [
      :api_key,
      :model,
      :base_url,
      :timeout
    ]

    @doc """
    Load configuration from application environment.
    """
    def load do
      %__MODULE__{
        api_key:
          Application.get_env(:agent_monitor, :llm_api_key, System.get_env("CLAUDE_API_KEY")),
        model: Application.get_env(:agent_monitor, :llm_model, "claude-3-5-sonnet-20241022"),
        base_url:
          Application.get_env(
            :agent_monitor,
            :llm_base_url,
            "https://api.anthropic.com/v1/messages"
          ),
        timeout: Application.get_env(:agent_monitor, :llm_timeout, 10_000)
      }
    end
  end

  defmodule Severity do
    @moduledoc """
    Alert severity levels.
    """
    def levels, do: [:info, :warning, :error, :critical]

    def from_string("INFO"), do: :info
    def from_string("WARNING"), do: :warning
    def from_string("ERROR"), do: :error
    def from_string("CRITICAL"), do: :critical
    def from_string(_), do: :warning

    def to_string(:info), do: "INFO"
    def to_string(:warning), do: "WARNING"
    def to_string(:error), do: "ERROR"
    def to_string(:critical), do: "CRITICAL"

    def weight(:info), do: 1
    def weight(:warning), do: 2
    def weight(:error), do: 3
    def weight(:critical), do: 4
  end

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Classify alert severity based on endpoint failure data.
  """
  def classify_severity(url, failure_data) do
    GenServer.call(__MODULE__, {:classify_severity, url, failure_data})
  end

  @doc """
  Get recovery suggestions for a failed endpoint.
  """
  def get_recovery_suggestions(url, failure_data) do
    GenServer.call(__MODULE__, {:get_recovery_suggestions, url, failure_data})
  end

  @doc """
  Analyze endpoint for intelligent insights.
  """
  def analyze_endpoint(url, metrics) do
    GenServer.call(__MODULE__, {:analyze_endpoint, url, metrics})
  end

  # Server Callbacks

  @impl true
  def init(_) do
    Logger.info("Starting LLM Router Service")

    config = Config.load()

    unless config.api_key do
      Logger.warning("⚠️  LLM API key not configured. Intelligent routing will be disabled.")
    end

    {:ok, %{config: config, request_count: 0}}
  end

  @impl true
  def handle_call({:classify_severity, url, failure_data}, _from, state) do
    result = do_classify_severity(url, failure_data, state.config)
    new_state = %{state | request_count: state.request_count + 1}
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:get_recovery_suggestions, url, failure_data}, _from, state) do
    result = do_get_recovery_suggestions(url, failure_data, state.config)
    new_state = %{state | request_count: state.request_count + 1}
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:analyze_endpoint, url, metrics}, _from, state) do
    result = do_analyze_endpoint(url, metrics, state.config)
    new_state = %{state | request_count: state.request_count + 1}
    {:reply, result, new_state}
  end

  # Private Functions

  defp do_classify_severity(_url, failure_data, %{api_key: nil} = _config) do
    fallback_classification(failure_data)
  end

  defp do_classify_severity(url, failure_data, config) do
    prompt = build_classification_prompt(url, failure_data)

    case call_llm(prompt, config) do
      {:ok, response} ->
        parse_severity_response(response)

      {:error, _reason} ->
        Logger.warning("LLM classification failed, using fallback logic")
        fallback_classification(failure_data)
    end
  end

  defp do_get_recovery_suggestions(_url, failure_data, %{api_key: nil} = _config) do
    fallback_recovery_suggestions(failure_data)
  end

  defp do_get_recovery_suggestions(url, failure_data, config) do
    prompt = build_recovery_prompt(url, failure_data)

    case call_llm(prompt, config) do
      {:ok, response} ->
        parse_recovery_response(response)

      {:error, _reason} ->
        Logger.warning("LLM recovery suggestions failed, using fallback")
        fallback_recovery_suggestions(failure_data)
    end
  end

  defp do_analyze_endpoint(_url, _metrics, %{api_key: nil} = _config) do
    {:ok,
     %{
       severity: :warning,
       summary: "LLM not configured - analysis unavailable",
       suggestions: ["Check endpoint connectivity", "Review recent logs"]
     }}
  end

  defp do_analyze_endpoint(url, metrics, config) do
    prompt = build_analysis_prompt(url, metrics)

    case call_llm(prompt, config) do
      {:ok, response} ->
        parse_analysis_response(response)

      {:error, _reason} ->
        Logger.warning("LLM analysis failed")

        {:ok,
         %{
           severity: :warning,
           summary: "Analysis unavailable - LLM request failed",
           suggestions: ["Check endpoint connectivity", "Review recent logs"]
         }}
    end
  end

  defp build_classification_prompt(url, failure_data) do
    """
    Analyze this endpoint failure and classify severity:

    Endpoint: #{url}
    Failure reason: #{Map.get(failure_data, :reason, "Unknown")}
    Response time: #{Map.get(failure_data, :duration_ms, 0)}ms
    Status code: #{Map.get(failure_data, :code, "N/A")}
    Consecutive failures: #{Map.get(failure_data, :consecutive_failures, 1)}

    Classify severity as one of:
    - INFO: Minor issues, informational only
    - WARNING: Degraded performance, needs attention
    - ERROR: Service degraded, affecting users
    - CRITICAL: Service down, urgent action required

    Return only the severity level (INFO, WARNING, ERROR, or CRITICAL).
    """
  end

  defp build_recovery_prompt(url, failure_data) do
    """
    Provide recovery suggestions for this endpoint failure:

    Endpoint: #{url}
    Failure reason: #{Map.get(failure_data, :reason, "Unknown")}
    Response time: #{Map.get(failure_data, :duration_ms, 0)}ms
    Status code: #{Map.get(failure_data, :code, "N/A")}
    Body size: #{Map.get(failure_data, :body_size, 0)} bytes

    Provide 2-4 specific, actionable recovery suggestions.
    Format as a numbered list (1. suggestion 1, 2. suggestion 2, etc.).
    Keep each suggestion concise and actionable.
    """
  end

  defp build_analysis_prompt(url, metrics) do
    """
    Analyze this endpoint's health and provide insights:

    Endpoint: #{url}
    Check count: #{Map.get(metrics, :check_count, 0)}
    Failure count: #{Map.get(metrics, :failure_count, 0)}
    Success rate: #{success_rate(metrics)}%
    Average response time: #{average_response_time(metrics)}ms
    Last check: #{Map.get(metrics, :last_check, "Never")}

    Provide:
    1. Severity level (INFO, WARNING, ERROR, CRITICAL)
    2. Brief summary of health (1 sentence)
    3. 2-4 actionable suggestions

    Format as JSON:
    {
      "severity": "SEVERITY",
      "summary": "summary text",
      "suggestions": ["suggestion 1", "suggestion 2"]
    }
    """
  end

  defp call_llm(prompt, %{api_key: api_key, model: model, base_url: base_url, timeout: timeout}) do
    headers = [
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"},
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]

    body =
      Jason.encode!(%{
        model: model,
        max_tokens: 1024,
        messages: [
          %{role: "user", content: prompt}
        ]
      })

    case HTTPoison.post(base_url, body, headers, timeout: timeout, recv_timeout: timeout) do
      {:ok, %{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"content" => [%{"text" => text}]}} ->
            {:ok, text}

          {:ok, other} ->
            Logger.error("Unexpected LLM response format: #{inspect(other)}")
            {:error, :unexpected_format}

          {:error, reason} ->
            Logger.error("Failed to decode LLM response: #{inspect(reason)}")
            {:error, :decode_error}
        end

      {:ok, %{status_code: status, body: body}} ->
        Logger.error("LLM API returned status #{status}: #{body}")
        {:error, :api_error}

      {:error, %{reason: reason}} ->
        Logger.error("LLM API request failed: #{inspect(reason)}")
        {:error, :request_error}
    end
  end

  defp parse_severity_response(response) do
    severity_str =
      response
      |> String.upcase()
      |> String.trim()

    severity = Severity.from_string(severity_str)

    {:ok, severity}
  end

  defp parse_recovery_response(response) do
    suggestions =
      response
      |> String.split("\n")
      |> Enum.filter(fn line ->
        String.match?(line, ~r/^\d+\./)
      end)
      |> Enum.map(fn line ->
        line
        |> String.replace(~r/^\d+\.\s*/, "")
        |> String.trim()
      end)
      |> Enum.reject(&(&1 == ""))

    {:ok, suggestions}
  end

  defp parse_analysis_response(response) do
    case Jason.decode(response) do
      {:ok, %{"severity" => severity_str, "summary" => summary, "suggestions" => suggestions}} ->
        severity = Severity.from_string(severity_str) || :warning
        {:ok, %{severity: severity, summary: summary, suggestions: suggestions}}

      _ ->
        {:ok,
         %{
           severity: :warning,
           summary: "Analysis returned unexpected format",
           suggestions: ["Review LLM response format"]
         }}
    end
  end

  defp fallback_classification(failure_data) do
    consecutive_failures = Map.get(failure_data, :consecutive_failures, 1)
    duration_ms = Map.get(failure_data, :duration_ms, 0)

    severity =
      cond do
        consecutive_failures >= 5 -> :critical
        consecutive_failures >= 3 -> :error
        duration_ms > 5000 -> :warning
        true -> :warning
      end

    {:ok, severity}
  end

  defp fallback_recovery_suggestions(failure_data) do
    reason = Map.get(failure_data, :reason, "Unknown error")
    code = Map.get(failure_data, :code)

    suggestions =
      cond do
        is_integer(code) and code >= 500 ->
          [
            "Check server logs for application errors",
            "Verify backend service availability",
            "Contact server administrators"
          ]

        is_integer(code) and code >= 400 ->
          [
            "Verify endpoint URL and parameters",
            "Check authentication credentials",
            "Review request payload format"
          ]

        reason =~ "timeout" ->
          [
            "Check network connectivity",
            "Increase timeout threshold",
            "Verify DNS resolution"
          ]

        true ->
          [
            "Check endpoint availability",
            "Review recent system changes",
            "Check network connectivity"
          ]
      end

    {:ok, suggestions}
  end

  defp success_rate(metrics) do
    check_count = Map.get(metrics, :check_count, 0)
    failure_count = Map.get(metrics, :failure_count, 0)

    if check_count > 0 do
      Float.round((check_count - failure_count) / check_count * 100, 1)
    else
      0.0
    end
  end

  defp average_response_time(metrics) do
    history = Map.get(metrics, :history, [])

    if Enum.empty?(history) do
      0
    else
      total =
        history
        |> Enum.map(&Map.get(&1, :duration_ms, 0))
        |> Enum.sum()

      Float.round(total / length(history), 1)
    end
  end
end
