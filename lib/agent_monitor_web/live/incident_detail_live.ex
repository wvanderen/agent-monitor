defmodule AgentMonitorWeb.IncidentDetailLive do
  use AgentMonitorWeb, :live_view

  alias AgentMonitor.Incident

  @impl true
  def mount(%{"id" => incident_id}, _session, socket) do
    incident = AgentMonitor.Repo.get!(AgentMonitor.Incident, incident_id)

    socket =
      assign(socket,
        incident: incident,
        comment_content: "",
        show_assign_modal: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("add_comment", %{"content" => content}, socket) do
    comment = %{
      content: content,
      author: "current_user"
    }

    socket =
      socket
      |> assign(comment_content: "")

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_assign_modal", _, socket) do
    {:noreply, assign(socket, show_assign_modal: true)}
  end

  @impl true
  def handle_event("close_assign_modal", _, socket) do
    {:noreply, assign(socket, show_assign_modal: false)}
  end
end
