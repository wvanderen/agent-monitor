defmodule AgentMonitorWeb.IncidentController do
  use AgentMonitorWeb, :controller

  import Ecto.Query

  def create(conn, %{"incident" => incident_params}) do
    incident_attrs =
      incident_params
      |> Map.put("detected_at", DateTime.utc_now())
      |> Map.put_new("status", "open")
      |> Map.put_new("severity", "P3")

    changeset = AgentMonitor.Incident.changeset(%AgentMonitor.Incident{}, incident_attrs)

    case AgentMonitor.Repo.insert(changeset) do
      {:ok, incident} ->
        # Start workflow for new incident
        workflow = create_workflow_for_incident(incident)

        Phoenix.PubSub.broadcast(AgentMonitor.PubSub, "incidents", {:incident_update, incident})

        conn
        |> put_status(:created)
        |> json(%{
          id: incident.id,
          title: incident.title,
          status: incident.status,
          severity: incident.severity,
          workflow_id: workflow.id
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, & &1)})
    end
  end

  def update(conn, %{"id" => id, "incident" => incident_params}) do
    incident = AgentMonitor.Repo.get!(AgentMonitor.Incident, id)

    changeset = AgentMonitor.Incident.changeset(incident, incident_params)

    case AgentMonitor.Repo.update(changeset) do
      {:ok, incident} ->
        Phoenix.PubSub.broadcast(AgentMonitor.PubSub, "incidents", {:incident_update, incident})

        conn
        |> put_status(:ok)
        |> json(%{
          id: incident.id,
          title: incident.title,
          status: incident.status,
          severity: incident.severity
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: Ecto.Changeset.traverse_errors(changeset, & &1)})
    end
  end

  defp create_workflow_for_incident(incident) do
    {:ok, workflow} =
      AgentMonitor.Workflow.changeset(%AgentMonitor.Workflow{}, %{
        incident_id: incident.id,
        status: :pending
      })
      |> AgentMonitor.Repo.insert()

    workflow
  end
end
