defmodule AgentMonitor.ApprovalWhitelistChecker do
  @moduledoc """
  Checks if approval is required based on whitelist rules.
  """

  alias AgentMonitor.ApprovalWhitelist
  alias AgentMonitor.Repo
  import Ecto.Query

  @doc """
  Check if approval is required for the given agent, action, and incident.
  Returns true if approval is required, false if pre-approved.
  """
  def approval_required?(agent_id, incident_type, risk_level, action \\ nil) do
    whitelisted =
      find_whitelist_entries(agent_id, incident_type, risk_level, action)
      |> Enum.reject(&ApprovalWhitelist.is_expired?/1)

    case whitelisted do
      [] -> true
      _entries -> false
    end
  end

  @doc """
  Add a whitelist entry.
  """
  def add_whitelist_entry(attrs) do
    %ApprovalWhitelist{}
    |> ApprovalWhitelist.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Remove a whitelist entry.
  """
  def remove_whitelist_entry(id) do
    case Repo.get(ApprovalWhitelist, id) do
      nil -> {:error, :not_found}
      entry -> Repo.delete(entry)
    end
  end

  @doc """
  List all active whitelist entries.
  """
  def list_active_entries do
    now = DateTime.utc_now()

    Repo.all(
      from(aw in ApprovalWhitelist,
        where: is_nil(aw.expires_at) or aw.expires_at > ^now,
        order_by: [desc: aw.inserted_at]
      )
    )
  end

  @doc """
  Get whitelist entries for a specific agent.
  """
  def get_agent_whitelist(agent_id) do
    now = DateTime.utc_now()

    Repo.all(
      from(aw in ApprovalWhitelist,
        where: aw.agent_id == ^agent_id and (is_nil(aw.expires_at) or aw.expires_at > ^now),
        order_by: [desc: aw.inserted_at]
      )
    )
  end

  # Private Functions

  defp find_whitelist_entries(agent_id, incident_type, risk_level, action) do
    query = from(aw in ApprovalWhitelist)

    query = if agent_id, do: where(query, [aw], aw.agent_id == ^agent_id), else: query

    query =
      if incident_type, do: where(query, [aw], aw.incident_type == ^incident_type), else: query

    query =
      if risk_level do
        where(query, [aw], aw.risk_level == ^risk_level or aw.risk_level == "all")
      else
        query
      end

    query =
      if action do
        where(
          query,
          [aw],
          is_nil(aw.action_pattern) or like(aw.action_pattern, ^"%#{action}%")
        )
      else
        query
      end

    Repo.all(query)
  end
end
