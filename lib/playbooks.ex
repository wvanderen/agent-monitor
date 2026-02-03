defmodule Playbooks do
  @moduledoc """
  GenServer for managing and executing playbooks.

  Provides playbook loading, execution, and step-by-step orchestration
  with retry logic and proper error handling.
  """

  use GenServer
  require Logger

  @type playbook_id :: String.t()
  @type playbook :: %{
          id: String.t(),
          name: String.t(),
          description: String.t(),
          steps: list(playbook_step()),
          timeout: pos_integer(),
          on_failure: :continue | :stop
        }

  @type playbook_step :: %{
          name: String.t(),
          type: :command | :restart | :check | :notify | :wait,
          params: map(),
          timeout: pos_integer(),
          on_failure: :continue | :stop | :retry,
          retry_count: non_neg_integer()
        }

  defstruct playbooks: %{},
            playbook_dir: "playbooks",
            running: %{}

  @doc """
  Start the playbook server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Run a playbook by ID.
  """
  def run(playbook_id, context \\ %{}, timeout \\ 5000) do
    GenServer.call(__MODULE__, {:run, playbook_id, context}, timeout)
  end

  @doc """
  List all available playbooks.
  """
  def list(timeout \\ 5000) do
    GenServer.call(__MODULE__, :list, timeout)
  end

  @doc """
  Get a playbook by ID.
  """
  def get(playbook_id, timeout \\ 5000) do
    GenServer.call(__MODULE__, {:get, playbook_id}, timeout)
  end

  @doc """
  Load playbooks from a directory.
  """
  def load_playbooks(dir \\ "playbooks") do
    GenServer.call(__MODULE__, {:load_playbooks, dir})
  end

  @doc """
  Validate a playbook definition.
  """
  def validate(playbook) do
    with :ok <- validate_playbook_structure(playbook),
         :ok <- validate_playbook_steps(playbook.steps) do
      :ok
    end
  end

  @doc """
  Execute a single playbook step (for testing).
  """
  def execute_step_public(step, context, timeout \\ 30000) do
    task = Task.async(fn -> do_execute_step(step, context) end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, result} -> result
      nil -> {:error, :timeout}
    end
  end

  @impl true
  def init(opts) do
    Logger.info("Starting Playbooks Server")

    playbook_dir = Keyword.get(opts, :playbook_dir, "playbooks")

    state = %__MODULE__{
      playbooks: %{},
      playbook_dir: playbook_dir,
      running: %{}
    }

    initial_playbooks = load_builtin_playbooks()
    state = %{state | playbooks: initial_playbooks}

    Logger.info("Loaded #{map_size(state.playbooks)} playbooks")

    {:ok, state}
  end

  @impl true
  def handle_call({:run, playbook_id, context}, _from, state) do
    case Map.get(state.playbooks, playbook_id) do
      nil ->
        {:reply, {:error, :playbook_not_found}, state}

      playbook ->
        case Map.get(state.running, playbook_id) do
          nil ->
            result = execute_playbook(playbook, context)
            {:reply, result, state}

          _pid ->
            {:reply, {:error, :playbook_already_running}, state}
        end
    end
  end

  @impl true
  def handle_call(:list, _from, state) do
    playbooks =
      state.playbooks
      |> Enum.map(fn {_id, playbook} ->
        %{id: playbook.id, name: playbook.name, description: playbook.description}
      end)

    {:reply, playbooks, state}
  end

  @impl true
  def handle_call({:get, playbook_id}, _from, state) do
    {:reply, Map.get(state.playbooks, playbook_id), state}
  end

  @impl true
  def handle_call({:load_playbooks, dir}, _from, state) do
    result = load_playbooks_from_directory(dir)

    case result do
      {:ok, playbooks} ->
        new_playbooks = Map.merge(state.playbooks, playbooks)
        {:reply, {:ok, map_size(playbooks)}, %{state | playbooks: new_playbooks}}

      _ ->
        {:reply, result, state}
    end
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @spec execute_playbook(map(), map()) :: {:ok, map()} | {:error, any()}
  defp execute_playbook(playbook, context) do
    Logger.info("Running playbook: #{playbook.name}")

    result =
      playbook.steps
      |> Enum.with_index()
      |> Enum.reduce_while(%{status: :running, results: []}, fn {step, idx}, acc ->
        Logger.info("Executing step #{idx + 1}/#{length(playbook.steps)}: #{step.name}")

        step_result = execute_step(step, context, playbook.timeout)

        case step_result do
          {:ok, output} ->
            {:cont, %{status: :running, results: [{step.name, output} | acc.results]}}

          {:error, reason} ->
            Logger.error("Step failed: #{step.name} - #{inspect(reason)}")

            case step.on_failure do
              :continue ->
                {:cont,
                 %{status: :running, results: [{step.name, {:error, reason}} | acc.results]}}

              :stop ->
                {:halt,
                 %{
                   status: :stopped,
                   error: {:step_failed, step.name, reason},
                   results: [{step.name, {:error, reason}} | acc.results]
                 }}

              :retry ->
                retry_count = Map.get(context, :retry_count, step.retry_count)

                if retry_count > 0 do
                  Logger.info("Retrying step: #{step.name} (attempts left: #{retry_count})")
                  :timer.sleep(1000)
                  execute_step(step, %{context | retry_count: retry_count - 1}, playbook.timeout)
                else
                  {:halt,
                   %{
                     status: :stopped,
                     error: {:max_retries, step.name},
                     results: [{step.name, {:error, :max_retries}} | acc.results]
                   }}
                end
            end
        end
      end)

    final_result =
      case result do
        %{status: :running, results: results} ->
          Logger.info("✓ Playbook #{playbook.id} completed successfully")
          {:ok, %{playbook: playbook.id, results: Enum.reverse(results)}}

        %{status: :stopped, error: error, results: _results} ->
          Logger.error("✗ Playbook #{playbook.id} failed: #{inspect(error)}")
          {:error, error}
      end

    final_result
  end

  defp execute_step(step, context, playbook_timeout) do
    timeout = Map.get(step, :timeout, playbook_timeout)

    task =
      Task.async(fn ->
        do_execute_step(step, context)
      end)

    case Task.yield(task, timeout) || Task.shutdown(task) do
      {:ok, {:ok, result}} ->
        {:ok, result}

      {:ok, {:error, reason}} ->
        {:error, reason}

      nil ->
        Logger.error("Step timeout: #{step.name}")
        {:error, :timeout}
    end
  end

  defp do_execute_step(step, context) do
    case step.type do
      :command ->
        execute_command_step(step, context)

      :restart ->
        execute_restart_step(step, context)

      :check ->
        execute_check_step(step, context)

      :notify ->
        execute_notify_step(step, context)

      :wait ->
        execute_wait_step(step, context)

      :unknown ->
        {:error, :unknown_step_type}
    end
  end

  defp execute_command_step(step, context) do
    command = render_template(Map.get(step.params, :command), context)
    args = Map.get(step.params, :args, []) |> Enum.map(&render_template(&1, context))

    Logger.info("Executing command: #{command} #{Enum.join(args, " ")}")

    try do
      {output, exit_code} =
        System.cmd(command, args,
          cd: Map.get(step.params, :cwd),
          stderr_to_stdout: true,
          into: []
        )

      if exit_code == 0 do
        {:ok, %{output: IO.iodata_to_binary(output), exit_code: exit_code}}
      else
        {:error, %{exit_code: exit_code, output: IO.iodata_to_binary(output)}}
      end
    rescue
      e ->
        {:error, %{exception: inspect(e)}}
    end
  end

  defp execute_restart_step(step, _context) do
    service = Map.get(step.params, :service)

    Logger.info("Restarting service: #{service}")

    case System.cmd("systemctl", ["restart", service], stderr_to_stdout: true, into: []) do
      {output, 0} ->
        {:ok, %{output: IO.iodata_to_binary(output)}}

      {output, exit_code} ->
        {:error, %{exit_code: exit_code, output: IO.iodata_to_binary(output)}}
    end
  end

  defp execute_check_step(step, _context) do
    url = Map.get(step.params, :url)

    Logger.info("Checking endpoint: #{url}")

    case HTTPoison.get(url, [], timeout: 5000, recv_timeout: 5000) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in 200..299 ->
        {:ok, %{status: :ok, code: code}}

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, %{status: :error, code: code}}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, %{reason: reason}}
    end
  end

  defp execute_notify_step(step, context) do
    Logger.info("Sending notification: #{step.name}")

    notification =
      Notifications.Notification.new(%{
        title: Map.get(step.params, :title, "Playbook Notification"),
        message: Map.get(step.params, :message, step.name),
        severity: Map.get(step.params, :severity, :info),
        metadata: context
      })

    case Notifications.Dispatcher.send_sync(notification) do
      results ->
        succeeded? = Enum.all?(results, fn {_channel, result} -> match?({:ok, _}, result) end)

        if succeeded? do
          {:ok, %{channels: Keyword.keys(results)}}
        else
          {:error, %{results: results}}
        end
    end
  end

  defp execute_wait_step(step, _context) do
    duration = Map.get(step.params, :duration, 5000)
    Logger.info("Waiting #{duration}ms")
    :timer.sleep(duration)
    {:ok, %{waited: duration}}
  end

  defp load_builtin_playbooks do
    %{
      "restart-failing-service" => %{
        id: "restart-failing-service",
        name: "Restart Failing Service",
        description: "Gracefully restart a failing service",
        timeout: 30000,
        on_failure: :stop,
        steps: [
          %{
            name: "Check service health",
            type: :check,
            params: %{url: "{{url}}"},
            timeout: 5000,
            on_failure: :continue,
            retry_count: 0
          },
          %{
            name: "Graceful shutdown wait",
            type: :wait,
            params: %{duration: 5000},
            timeout: 6000,
            on_failure: :stop,
            retry_count: 0
          },
          %{
            name: "Restart service",
            type: :restart,
            params: %{service: "{{service_name}}"},
            timeout: 10000,
            on_failure: :stop,
            retry_count: 2
          },
          %{
            name: "Verify service is up",
            type: :check,
            params: %{url: "{{url}}"},
            timeout: 10000,
            on_failure: :stop,
            retry_count: 3
          },
          %{
            name: "Notify success",
            type: :notify,
            params: %{
              title: "Service Restarted",
              message: "Service {{service_name}} has been successfully restarted",
              severity: :info
            },
            timeout: 5000,
            on_failure: :continue,
            retry_count: 0
          }
        ]
      }
    }
  end

  defp load_playbooks_from_directory(dir) do
    if File.dir?(dir) do
      playbooks =
        dir
        |> File.ls!()
        |> Enum.filter(&String.ends_with?(&1, [".yml", ".yaml", ".json"]))
        |> Enum.map(&Path.join(dir, &1))
        |> Enum.reduce(%{}, fn path, acc ->
          case load_playbook_file(path) do
            {:ok, playbook} -> Map.put(acc, playbook.id, playbook)
            {:error, _} -> acc
          end
        end)

      {:ok, playbooks}
    else
      Logger.warning("Playbook directory not found: #{dir}")
      {:ok, %{}}
    end
  end

  defp load_playbook_file(path) do
    case Path.extname(path) do
      ".json" ->
        case File.read(path) do
          {:ok, content} ->
            case Jason.decode(content, keys: :atoms) do
              {:ok, playbook} ->
                case validate(playbook) do
                  :ok -> {:ok, playbook}
                  {:error, reason} -> {:error, reason}
                end

              {:error, reason} ->
                {:error, {:decode_error, reason}}
            end

          {:error, reason} ->
            {:error, {:read_error, reason}}
        end

      ext when ext in [".yml", ".yaml"] ->
        try do
          {:ok, file_content} = File.read(path)
          [parsed] = :yamerl.decode(String.to_charlist(file_content), [:str_node_as_binary])
          playbook = yamerl_to_map(parsed)

          case validate(playbook) do
            :ok -> {:ok, playbook}
            {:error, reason} -> {:error, reason}
          end
        rescue
          error ->
            {:error, {:parse_error, error}}
        end

      _ ->
        {:error, :unsupported_format}
    end
  end

  defp yamerl_to_map(list) when is_list(list) do
    Enum.map(list, &yamerl_to_map/1)
  end

  defp yamerl_to_map({:yamerl_seq, seq}) do
    Enum.map(seq, &yamerl_to_map/1)
  end

  defp yamerl_to_map({:yamerl_seq, _, seq}) do
    Enum.map(seq, &yamerl_to_map/1)
  end

  defp yamerl_to_map({:yamerl_map, map}) do
    Enum.map(map, fn {[k], v} -> {String.to_atom(k), yamerl_to_map(v)} end)
    |> Map.new()
  end

  defp yamerl_to_map({:yamerl_map, _, map}) do
    Enum.map(map, fn {[k], v} -> {String.to_atom(k), yamerl_to_map(v)} end)
    |> Map.new()
  end

  defp yamerl_to_map(value), do: value

  defp validate_playbook_structure(playbook) do
    required_fields = [:id, :name, :steps]

    missing =
      Enum.filter(required_fields, fn field ->
        not Map.has_key?(playbook, field)
      end)

    if Enum.empty?(missing) do
      :ok
    else
      {:error, {:missing_fields, missing}}
    end
  end

  defp validate_playbook_steps(steps) when is_list(steps) do
    errors =
      Enum.with_index(steps)
      |> Enum.reduce([], fn {step, idx}, acc ->
        case validate_playbook_step(step) do
          :ok -> acc
          {:error, reason} -> [{idx, reason} | acc]
        end
      end)

    if Enum.empty?(errors) do
      :ok
    else
      {:error, {:invalid_steps, Enum.reverse(errors)}}
    end
  end

  defp validate_playbook_step(step) do
    required_fields = [:name, :type]

    missing =
      Enum.filter(required_fields, fn field ->
        not Map.has_key?(step, field)
      end)

    if Enum.empty?(missing) do
      valid_types = [:command, :restart, :check, :notify, :wait]

      if step.type in valid_types do
        :ok
      else
        {:error, {:invalid_type, step.type}}
      end
    else
      {:error, {:missing_fields, missing}}
    end
  end

  defp render_template(template, context) when is_binary(template) do
    Regex.replace(~r/\{\{(\w+)\}\}/, template, fn _full, key ->
      Map.get(context, String.to_atom(key), "")
    end)
  end

  defp render_template(template, _context), do: template
end
