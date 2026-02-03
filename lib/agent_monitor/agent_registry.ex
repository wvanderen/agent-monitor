defmodule AgentMonitor.AgentRegistry do
  @moduledoc """
  Manages agent installation and registry from marketplace.
  """
  use GenServer
  require Logger
  import Ecto.Query

  alias AgentMonitor.MarketplaceAgent
  alias AgentMonitor.Repo

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def list_agents(opts \\ []) do
    GenServer.call(__MODULE__, {:list_agents, opts})
  end

  def get_agent(agent_id) do
    GenServer.call(__MODULE__, {:get_agent, agent_id})
  end

  def install_agent(agent_id, user_id \\ "system") do
    GenServer.call(__MODULE__, {:install_agent, agent_id, user_id})
  end

  def uninstall_agent(agent_id) do
    GenServer.call(__MODULE__, {:uninstall_agent, agent_id})
  end

  def filter_by_capability(capability) do
    GenServer.call(__MODULE__, {:filter_by_capability, capability})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting AgentRegistry")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:list_agents, opts}, _from, state) do
    query = from(ma in MarketplaceAgent, where: ma.is_active == true)

    query =
      if opts[:installed_only] do
        where(query, [ma], ma.is_installed == true)
      else
        query
      end

    query =
      if opts[:not_installed_only] do
        where(query, [ma], ma.is_installed == false)
      else
        query
      end

    agents = Repo.all(query)
    {:reply, agents, state}
  end

  @impl true
  def handle_call({:get_agent, agent_id}, _from, state) do
    agent = Repo.get(MarketplaceAgent, agent_id)
    {:reply, agent, state}
  end

  @impl true
  def handle_call({:install_agent, agent_id, user_id}, _from, state) do
    case Repo.get(MarketplaceAgent, agent_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      agent ->
        changeset = MarketplaceAgent.install_changeset(agent)
        {:ok, updated_agent} = Repo.update(changeset)

        Logger.info("Agent #{agent.name} installed by #{user_id}")

        {:reply, {:ok, updated_agent}, state}
    end
  end

  @impl true
  def handle_call({:uninstall_agent, agent_id}, _from, state) do
    case Repo.get(MarketplaceAgent, agent_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      agent ->
        changeset = MarketplaceAgent.uninstall_changeset(agent)
        {:ok, updated_agent} = Repo.update(changeset)

        Logger.info("Agent #{agent.name} uninstalled")

        {:reply, {:ok, updated_agent}, state}
    end
  end

  @impl true
  def handle_call({:filter_by_capability, capability}, _from, state) do
    agents =
      MarketplaceAgent
      |> Repo.all()
      |> Enum.filter(fn ma ->
        ma.is_active and capability in ma.capabilities
      end)

    {:reply, agents, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
