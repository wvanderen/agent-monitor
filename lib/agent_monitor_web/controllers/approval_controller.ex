defmodule AgentMonitorWeb.ApprovalController do
  use AgentMonitorWeb, :controller

  def respond(conn, %{"id" => id, "action" => action, "user" => user}) do
    approval = AgentMonitor.Repo.get!(AgentMonitor.ApprovalRequest, id)

    if AgentMonitor.ApprovalRequest.is_expired?(approval) do
      {:ok, _} =
        AgentMonitor.Repo.update(AgentMonitor.ApprovalRequest.expire_changeset(approval))

      conn
      |> put_status(:unprocessable_entity)
      |> json(%{error: "Approval request has expired"})
    else
      case process_approval(approval, action, user, conn.params) do
        {:ok, approval} ->
          Phoenix.PubSub.broadcast(AgentMonitor.PubSub, "approvals", {:approval_update, approval})

          conn
          |> put_status(:ok)
          |> json(%{
            id: approval.id,
            status: approval.status,
            action: approval.action
          })

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{
            errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
          })
      end
    end
  end

  defp process_approval(approval, "approve", user, params) do
    modifications = Map.get(params, "modifications", nil)

    AgentMonitor.Repo.update(
      AgentMonitor.ApprovalRequest.approve_changeset(approval, user, modifications)
    )
  end

  defp process_approval(approval, "reject", user, params) do
    reason = Map.get(params, "reason", "No reason provided")

    AgentMonitor.Repo.update(
      AgentMonitor.ApprovalRequest.reject_changeset(approval, user, reason)
    )
  end

  defp process_approval(_approval, action, _user, _params) do
    {:error, Ecto.Changeset.add_error(%Ecto.Changeset{}, :action, "Unknown action: #{action}")}
  end
end
