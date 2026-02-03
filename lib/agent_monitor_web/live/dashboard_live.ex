defmodule AgentMonitorWeb.DashboardLive do
  use AgentMonitorWeb, :live_view
  import Ecto.Query

  alias AgentMonitor.UptimeCollector

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AgentMonitor.PubSub, "workflows")
      Phoenix.PubSub.subscribe(AgentMonitor.PubSub, "incidents")
      Phoenix.PubSub.subscribe(AgentMonitor.PubSub, "uptime")
    end

    socket =
      assign(socket,
        active_workflows: count_active_workflows(),
        open_incidents: count_open_incidents(),
        uptime: calculate_uptime(),
        agents_running: count_agents_running(),
        workflows: list_active_workflows(),
        incidents: list_recent_incidents()
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:workflow_update, _workflow}, socket) do
    {:noreply,
     assign(socket,
       workflows: list_active_workflows(),
       active_workflows: count_active_workflows()
     )}
  end

  @impl true
  def handle_info({:incident_update, _incident}, socket) do
    {:noreply,
     assign(socket, incidents: list_recent_incidents(), open_incidents: count_open_incidents())}
  end

  defp count_active_workflows do
    from(w in AgentMonitor.Workflow, where: w.status == :in_progress)
    |> AgentMonitor.Repo.aggregate(:count)
  end

  defp count_open_incidents do
    from(i in AgentMonitor.Incident, where: i.status in [:open, :in_progress])
    |> AgentMonitor.Repo.aggregate(:count)
  end

  defp calculate_uptime do
    services = get_monitored_services()

    if Enum.empty?(services) do
      "No services monitored"
    else
      uptime_percentages =
        Enum.map(services, fn service_id ->
          UptimeCollector.get_uptime_percentage(service_id)
        end)

      avg_uptime =
        if Enum.empty?(uptime_percentages) do
          0.0
        else
          Enum.sum(uptime_percentages) / length(uptime_percentages)
        end

      "#{Float.round(avg_uptime, 2)}%"
    end
  end

  defp get_monitored_services do
    from(i in AgentMonitor.Incident,
      select: i.service_id,
      distinct: i.service_id,
      where: i.service_id != "" and not is_nil(i.service_id),
      order_by: [asc: i.service_id]
    )
    |> AgentMonitor.Repo.all()
    |> Enum.filter(& &1)
  end

  defp count_agents_running do
    from(w in AgentMonitor.Workflow, where: w.status == :in_progress)
    |> AgentMonitor.Repo.aggregate(:count)
  end

  defp list_active_workflows(limit \\ 5) do
    from(w in AgentMonitor.Workflow,
      where: w.status in [:pending, :in_progress],
      order_by: [desc: w.inserted_at],
      limit: ^limit
    )
    |> AgentMonitor.Repo.all()
  end

  defp list_recent_incidents(limit \\ 5) do
    from(i in AgentMonitor.Incident,
      order_by: [desc: i.inserted_at],
      limit: ^limit
    )
    |> AgentMonitor.Repo.all()
  end
end
