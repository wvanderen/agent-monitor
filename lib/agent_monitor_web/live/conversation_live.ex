defmodule AgentMonitorWeb.ConversationLive do
  use AgentMonitorWeb, :live_view

  import Ecto.Query
  alias AgentMonitor.Conversation
  alias AgentMonitor.Workflow

  @impl true
  def mount(%{"workflow_id" => workflow_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AgentMonitor.PubSub, "conversations:#{workflow_id}")
    end

    socket =
      assign(socket,
        workflow_id: workflow_id,
        workflow: get_workflow(workflow_id),
        messages: list_messages(workflow_id),
        filter_agent: :all
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    messages = socket.assigns.messages ++ [message]
    {:noreply, assign(socket, messages: messages)}
  end

  @impl true
  def handle_event("filter_agent", %{"agent_id" => agent_id}, socket) do
    agent_filter = if agent_id == "all", do: :all, else: agent_id
    messages = list_messages(socket.assigns.workflow_id, agent_filter)

    {:noreply, assign(socket, filter_agent: agent_filter, messages: messages)}
  end

  defp get_workflow(workflow_id) do
    AgentMonitor.Repo.get(AgentMonitor.Workflow, workflow_id)
  end

  defp list_messages(workflow_id) do
    list_messages(workflow_id, :all)
  end

  defp list_messages(workflow_id, agent_filter) do
    query =
      from(c in AgentMonitor.Conversation,
        where: c.workflow_id == ^workflow_id,
        order_by: [asc: c.inserted_at]
      )

    query =
      if agent_filter != :all do
        where(query, [c], c.agent_id == ^agent_filter)
      else
        query
      end

    AgentMonitor.Repo.all(query)
  end

  defp agent_color(agent_id) do
    hash = :erlang.phash2(agent_id, 0xFFFFFF)
    "hsl(#{rem(hash, 360)}, 70%, 50%)"
  end
end
