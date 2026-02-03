defmodule AgentMonitor.WorkflowDiagramLive do
  use AgentMonitorWeb, :live_view

  alias AgentMonitor.Workflow
  alias AgentMonitor.Repo

  @impl true
  def mount(%{"workflow_id" => workflow_id}, _session, socket) do
    workflow = Repo.get(Workflow, workflow_id)

    socket =
      assign(socket,
        workflow: workflow,
        diagram: generate_mermaid_diagram(workflow),
        show_node_details: false,
        selected_node: nil
      )

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, workflow: nil, diagram: nil)}
  end

  @impl true
  def handle_event("select_node", %{"node_id" => node_id}, socket) do
    workflow = socket.assigns.workflow
    step_data = find_step_data(workflow, node_id)

    socket =
      assign(socket,
        show_node_details: true,
        selected_node: step_data
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_details", _params, socket) do
    {:noreply,
     assign(socket,
       show_node_details: false,
       selected_node: nil
     )}
  end

  defp generate_mermaid_diagram(nil), do: nil

  defp generate_mermaid_diagram(workflow) do
    steps = workflow.steps || []

    graph_def = """
    graph TD
    """

    nodes =
      steps
      |> Enum.with_index()
      |> Enum.map(fn {step, index} ->
        node_id = "step#{index}"
        agent_name = get_agent_name(step)
        status = get_step_status(step)

        status_style =
          case status do
            :completed -> "completed"
            :failed -> "failed"
            :in_progress -> "active"
            _ -> "pending"
          end

        """
        #{node_id}[#{agent_name}]:::#{status_style}
        """
      end)

    edges =
      steps
      |> Enum.with_index()
      |> Enum.map(fn {_step, index} ->
        if index > 0 do
          """
          step#{index - 1} --> step#{index}
          """
        else
          ""
        end
      end)

    graph_def <>
      Enum.join(nodes, "\n") <>
      Enum.join(edges, "\n") <>
      """
      classDef completed fill:#90EE90,stroke:#333,stroke-width:2px
      classDef failed fill:#FFB3BA,stroke:#333,stroke-width:2px
      classDef active fill:#FFD700,stroke:#333,stroke-width:4px
      classDef pending fill:#D3D3D3,stroke:#333,stroke-width:2px
      """
  end

  defp get_agent_name(%{agent: agent}), do: agent
  defp get_agent_name(%{parallel_branches: count}), do: "Parallel Branch (#{count} agents)"
  defp get_agent_name(_step), do: "Unknown"

  defp get_step_status(%{status: status}), do: status
  defp get_step_status(_step), do: :pending

  defp find_step_data(workflow, node_id) do
    step_index =
      node_id
      |> String.replace_prefix("step", "")
      |> String.to_integer()

    Enum.at(workflow.steps, step_index)
  end
end
