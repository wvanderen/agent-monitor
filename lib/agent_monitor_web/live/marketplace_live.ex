defmodule AgentMonitorWeb.MarketplaceLive do
  use AgentMonitorWeb, :live_view

  alias AgentMonitor.AgentRegistry

  @impl true
  def mount(_params, _session, socket) do
    agents = list_marketplace_agents()

    socket =
      assign(socket,
        agents: agents,
        filter_capability: :all
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("filter_capability", %{"capability" => capability}, socket) do
    capability_atom = String.to_atom(capability)

    socket =
      assign(socket,
        filter_capability: capability_atom,
        agents: list_marketplace_agents_by_capability(capability_atom)
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("install", %{"agent_id" => agent_id}, socket) do
    case AgentRegistry.install_agent(agent_id, "current_user") do
      {:ok, _agent} ->
        {:noreply, put_flash(socket, :info, "Agent installed successfully")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to install agent")}
    end
  end

  defp list_marketplace_agents do
    AgentRegistry.list_agents()
  end

  defp list_marketplace_agents_by_capability(:all) do
    list_marketplace_agents()
  end

  defp list_marketplace_agents_by_capability(capability) do
    AgentRegistry.filter_by_capability(capability)
  end
end
