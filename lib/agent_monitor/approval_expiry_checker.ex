defmodule AgentMonitor.ApprovalExpiryChecker do
  @moduledoc """
  Periodically checks for expired approval requests and auto-rejects them.
  """

  use GenServer
  require Logger

  alias AgentMonitor.ApprovalRequest
  alias AgentMonitor.Repo

  import Ecto.Query

  @check_interval :timer.minutes(5)

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def check_expired_approvals do
    GenServer.cast(__MODULE__, :check_expired)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    schedule_next_check()

    Logger.info("Starting ApprovalExpiryChecker")

    {:ok, %{}}
  end

  @impl true
  def handle_cast(:check_expired, state) do
    expired_approvals = find_expired_approvals()

    Enum.each(expired_approvals, fn approval ->
      expire_approval(approval)
    end)

    if length(expired_approvals) > 0 do
      Logger.info("Auto-rejected #{length(expired_approvals)} expired approval(s)")
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:check_expired, state) do
    check_expired_approvals()
    schedule_next_check()

    {:noreply, state}
  end

  # Private Functions

  defp schedule_next_check do
    Process.send_after(self(), :check_expired, @check_interval)
  end

  defp find_expired_approvals do
    now = DateTime.utc_now()

    from(a in ApprovalRequest,
      where:
        a.status == :pending and
          a.expires_at < ^now
    )
    |> Repo.all()
  end

  defp expire_approval(approval) do
    changeset = ApprovalRequest.expire_changeset(approval)

    case Repo.update(changeset) do
      {:ok, _expired} ->
        Logger.info("Expired approval request #{approval.id} for agent #{approval.agent_id}")

        Phoenix.PubSub.broadcast(
          AgentMonitor.PubSub,
          "approvals",
          {:approval_updated, approval}
        )

        :ok

      {:error, changeset} ->
        Logger.error("Failed to expire approval #{approval.id}: #{inspect(changeset.errors)}")
        :error
    end
  end
end
