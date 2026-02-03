defmodule AgentMonitorWeb.IncidentLive do
  use AgentMonitorWeb, :live_view

  import Ecto.Query
  alias AgentMonitor.Incident

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        incidents: list_incidents(),
        filter_status: :all,
        filter_severity: :all
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_status", %{"status" => status}, socket) do
    socket =
      assign(socket,
        filter_status: String.to_atom(status),
        incidents: list_incidents(socket.assigns.filter_severity, String.to_atom(status))
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_severity", %{"severity" => severity}, socket) do
    socket =
      assign(socket,
        filter_severity: String.to_atom(severity),
        incidents: list_incidents(String.to_atom(severity), socket.assigns.filter_status)
      )

    {:noreply, socket}
  end

  defp list_incidents do
    list_incidents(:all, :all)
  end

  defp list_incidents(filter_severity, filter_status) do
    base_query = from(i in Incident)

    severity_query =
      if filter_severity != :all do
        where(base_query, [i], i.severity == ^filter_severity)
      else
        base_query
      end

    final_query =
      if filter_status != :all do
        where(severity_query, [i], i.status == ^filter_status)
      else
        severity_query
      end

    ordered_query = order_by(final_query, [i], desc: i.inserted_at)
    AgentMonitor.Repo.all(ordered_query)
  end

  defp status_badge(:open), do: "bg-green-100 text-green-800"
  defp status_badge(:in_progress), do: "bg-blue-100 text-blue-800"
  defp status_badge(:resolved), do: "bg-purple-100 text-purple-800"
  defp status_badge(:closed), do: "bg-gray-100 text-gray-800"
  defp status_badge(:reopened), do: "bg-yellow-100 text-yellow-800"

  defp severity_badge(:P1), do: "bg-red-100 text-red-800"
  defp severity_badge(:P2), do: "bg-orange-100 text-orange-800"
  defp severity_badge(:P3), do: "bg-yellow-100 text-yellow-800"
  defp severity_badge(:P4), do: "bg-green-100 text-green-800"
end
