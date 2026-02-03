defmodule AgentMonitorWeb.ConversationLive do
  use AgentMonitorWeb, :live_view

  import Ecto.Query

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
        filter_agent: :all,
        search_keyword: "",
        time_from: nil,
        time_to: nil
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

    messages =
      list_messages(
        socket.assigns.workflow_id,
        agent_filter,
        socket.assigns.search_keyword,
        socket.assigns.time_from,
        socket.assigns.time_to
      )

    {:noreply, assign(socket, filter_agent: agent_filter, messages: messages)}
  end

  @impl true
  def handle_event("search_keyword", %{"keyword" => keyword}, socket) do
    messages =
      list_messages(
        socket.assigns.workflow_id,
        socket.assigns.filter_agent,
        keyword,
        socket.assigns.time_from,
        socket.assigns.time_to
      )

    {:noreply, assign(socket, search_keyword: keyword, messages: messages)}
  end

  @impl true
  def handle_event("filter_time_range", %{"from" => from_str, "to" => to_str}, socket) do
    time_from = if from_str == "", do: nil, else: parse_datetime(from_str)
    time_to = if to_str == "", do: nil, else: parse_datetime(to_str)

    messages =
      list_messages(
        socket.assigns.workflow_id,
        socket.assigns.filter_agent,
        socket.assigns.search_keyword,
        time_from,
        time_to
      )

    {:noreply, assign(socket, time_from: time_from, time_to: time_to, messages: messages)}
  end

  @impl true
  def handle_event("clear_filters", %{}, socket) do
    messages = list_messages(socket.assigns.workflow_id)

    {:noreply,
     assign(socket,
       filter_agent: :all,
       search_keyword: "",
       time_from: nil,
       time_to: nil,
       messages: messages
     )}
  end

  defp get_workflow(workflow_id) do
    AgentMonitor.Repo.get(AgentMonitor.Workflow, workflow_id)
  end

  defp list_messages(workflow_id) do
    list_messages(workflow_id, :all, "", nil, nil)
  end

  defp list_messages(workflow_id, agent_filter, search_keyword, time_from, time_to) do
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

    query =
      if search_keyword != "" and search_keyword != nil do
        where(query, [c], like(c.content, ^"%#{search_keyword}%"))
      else
        query
      end

    query =
      if time_from do
        where(query, [c], c.inserted_at >= ^time_from)
      else
        query
      end

    query =
      if time_to do
        where(query, [c], c.inserted_at <= ^time_to)
      else
        query
      end

    AgentMonitor.Repo.all(query)
  end

  defp parse_datetime(date_str) do
    case DateTime.from_iso8601(date_str) do
      {:ok, datetime} -> datetime
      _ -> nil
    end
  end

  defp agent_color(agent_id) do
    hash = :erlang.phash2(agent_id, 0xFFFFFF)
    "hsl(#{rem(hash, 360)}, 70%, 50%)"
  end
end
