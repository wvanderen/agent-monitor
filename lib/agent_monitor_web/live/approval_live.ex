defmodule AgentMonitorWeb.ApprovalLive do
  use AgentMonitorWeb, :live_view
  import Ecto.Query

  alias AgentMonitor.ApprovalRequest
  alias AgentMonitor.Workflow
  alias AgentMonitor.Repo

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(AgentMonitor.PubSub, "approvals")
    end

    socket =
      assign(socket,
        approvals: list_pending_approvals(),
        show_details: false,
        selected_approval: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_info({:approval_created, _approval}, socket) do
    {:noreply, assign(socket, approvals: list_pending_approvals())}
  end

  @impl true
  def handle_info({:approval_updated, _approval}, socket) do
    {:noreply, assign(socket, approvals: list_pending_approvals())}
  end

  @impl true
  def handle_event("approve", %{"approval_id" => approval_id}, socket) do
    case Repo.get(ApprovalRequest, approval_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Approval not found")}

      approval ->
        changeset = ApprovalRequest.approve_changeset(approval, "current_user")

        case Repo.update(changeset) do
          {:ok, _updated} ->
            Phoenix.PubSub.broadcast(
              AgentMonitor.PubSub,
              "approvals",
              {:approval_updated, approval}
            )

            {:noreply, put_flash(socket, :info, "Approval approved")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to approve")}
        end
    end
  end

  @impl true
  def handle_event("reject", %{"approval_id" => approval_id, "reason" => reason}, socket) do
    case Repo.get(ApprovalRequest, approval_id) do
      nil ->
        {:noreply, put_flash(socket, :error, "Approval not found")}

      approval ->
        changeset = ApprovalRequest.reject_changeset(approval, "current_user", reason)

        case Repo.update(changeset) do
          {:ok, _updated} ->
            Phoenix.PubSub.broadcast(
              AgentMonitor.PubSub,
              "approvals",
              {:approval_updated, approval}
            )

            {:noreply, put_flash(socket, :info, "Approval rejected")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to reject")}
        end
    end
  end

  @impl true
  def handle_event("show_details", %{"approval_id" => approval_id}, socket) do
    approval = Repo.get(ApprovalRequest, approval_id)

    socket =
      assign(socket,
        show_details: true,
        selected_approval: approval
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("close_details", _params, socket) do
    socket =
      assign(socket,
        show_details: false,
        selected_approval: nil
      )

    {:noreply, socket}
  end

  defp list_pending_approvals do
    from(a in ApprovalRequest,
      where: a.status == :pending,
      order_by: [desc: a.inserted_at],
      preload: [:workflow]
    )
    |> Repo.all()
  end

  defp risk_badge(:low), do: "bg-green-100 text-green-800"
  defp risk_badge(:medium), do: "bg-yellow-100 text-yellow-800"
  defp risk_badge(:high), do: "bg-orange-100 text-orange-800"
  defp risk_badge(:critical), do: "bg-red-100 text-red-800"
  defp risk_badge(_), do: "bg-gray-100 text-gray-800"

  defp is_expired?(approval) do
    DateTime.compare(DateTime.utc_now(), approval.expires_at) != :lt
  end
end

defp expires_at_class(approval) do
  if is_expired?(approval) do
    "mt-1 text-sm text-gray-900 text-red-600"
  else
    "mt-1 text-sm text-gray-900"
  end
end
