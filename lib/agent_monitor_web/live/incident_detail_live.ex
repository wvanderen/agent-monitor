defmodule AgentMonitorWeb.IncidentDetailLive do
  use AgentMonitorWeb, :live_view

  alias AgentMonitor.Incident
  alias AgentMonitor.Comment
  alias AgentMonitor.Repo

  @impl true
  def mount(%{"id" => incident_id}, _session, socket) do
    incident = AgentMonitor.Repo.get!(AgentMonitor.Incident, incident_id)

    socket =
      assign(socket,
        incident: incident,
        comment_content: "",
        show_assign_modal: false,
        assigned_to: incident.assigned_to || ""
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("add_comment", %{"content" => content}, socket) do
    comment_attrs = %{
      content: content,
      author: "current_user",
      incident_id: socket.assigns.incident.id
    }

    case Repo.insert(Comment.changeset(%Comment{}, comment_attrs)) do
      {:ok, _comment} ->
        socket =
          socket
          |> assign(comment_content: "")
          |> put_flash(:info, "Comment added successfully")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply,
         put_flash(socket, :error, "Failed to add comment: #{inspect(changeset.errors)}")}
    end
  end

  @impl true
  def handle_event("show_assign_modal", _, socket) do
    {:noreply, assign(socket, show_assign_modal: true)}
  end

  @impl true
  def handle_event("close_assign_modal", _, socket) do
    {:noreply, assign(socket, show_assign_modal: false)}
  end

  @impl true
  def handle_event("assign_incident", %{"assigned_to" => assigned_to}, socket) do
    incident = socket.assigns.incident

    case Repo.update(Incident.assign_changeset(incident, %{assigned_to: assigned_to})) do
      {:ok, _updated_incident} ->
        socket =
          socket
          |> assign(incident: Map.put(incident, :assigned_to, assigned_to))
          |> assign(show_assign_modal: false)
          |> put_flash(:info, "Incident assigned successfully")

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply,
         put_flash(socket, :error, "Failed to assign incident: #{inspect(changeset.errors)}")}
    end
  end
end
