defmodule AgentMonitorWeb.WorkflowDetailLive do
  use AgentMonitorWeb, :live_view

  import Ecto.Query
  alias AgentMonitor.Workflow

  @impl true
  def mount(%{"id" => workflow_id}, _session, socket) do
    workflow = AgentMonitor.Repo.get!(AgentMonitor.Workflow, workflow_id)

    socket =
      assign(socket,
        workflow: workflow,
        conversations: list_conversations(workflow_id),
        context_versions: list_context_versions(workflow_id)
      )

    {:ok, socket}
  end

  defp list_conversations(workflow_id) do
    from(c in AgentMonitor.Conversation,
      where: c.workflow_id == ^workflow_id,
      order_by: [asc: c.inserted_at]
    )
    |> AgentMonitor.Repo.all()
  end

  defp list_context_versions(workflow_id) do
    from(cv in AgentMonitor.ContextVersion,
      where: cv.workflow_id == ^workflow_id,
      order_by: [asc: cv.step_number]
    )
    |> AgentMonitor.Repo.all()
  end
end
