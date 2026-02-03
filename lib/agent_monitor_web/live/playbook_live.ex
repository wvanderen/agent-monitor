defmodule AgentMonitorWeb.PlaybookLive do
  use AgentMonitorWeb, :live_view

  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        playbooks: list_playbooks()
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("create", _params, socket) do
    {:noreply, push_navigate(socket, ~p"/playbooks/new")}
  end

  defp list_playbooks do
    from(p in AgentMonitor.Playbook,
      where: p.is_active == true,
      order_by: [desc: p.inserted_at]
    )
    |> AgentMonitor.Repo.all()
  end
end
