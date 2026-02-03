import Ecto.Query

alias AgentMonitor.Repo

defmodule AgentMonitor.Seeds do
  def run do
    seed_playbooks()
    seed_incidents()
  end

  defp seed_playbooks do
    IO.puts("Seeding playbooks...")

    playbooks = [
      %{
        name: "Service Outage Recovery",
        description: "Standard playbook for service outage incidents",
        incident_type: "service_outage",
        service: "general",
        variables: [
          %{
            "name" => "service_name",
            "default_value" => "api",
            "description" => "Name of the service that is down"
          },
          %{
            "name" => "max_retries",
            "default_value" => "3",
            "description" => "Maximum retry attempts"
          }
        ],
        steps: [
          %{
            "agent" => "monitor_agent",
            "instructions" => "Check {{service_name}} endpoint availability",
            "requires_approval" => false
          },
          %{
            "agent" => "investigate_agent",
            "instructions" =>
              "Analyze logs and metrics for {{service_name}} to determine root cause",
            "requires_approval" => false
          },
          %{
            "agent" => "remediate_agent",
            "instructions" => "Restart {{service_name}} service if appropriate",
            "requires_approval" => true
          },
          %{
            "agent" => "verify_agent",
            "instructions" => "Verify {{service_name}} is operational after remediation",
            "requires_approval" => false
          }
        ],
        version: "1.0.0",
        author: "system"
      },
      %{
        name: "Performance Degradation",
        description: "Playbook for slow or degraded service performance",
        incident_type: "performance_degradation",
        service: "general",
        variables: [
          %{
            "name" => "service_name",
            "default_value" => "api",
            "description" => "Service experiencing performance issues"
          },
          %{
            "name" => "threshold_ms",
            "default_value" => "500",
            "description" => "Response time threshold in milliseconds"
          }
        ],
        steps: [
          %{
            "agent" => "monitor_agent",
            "instructions" => "Monitor {{service_name}} response times",
            "requires_approval" => false
          },
          %{
            "agent" => "investigate_agent",
            "instructions" =>
              "Investigate performance metrics and slow queries for {{service_name}}",
            "requires_approval" => false
          },
          %{
            "agent" => "remediate_agent",
            "instructions" => "Scale up {{service_name}} resources if needed",
            "requires_approval" => true
          }
        ],
        version: "1.0.0",
        author: "system"
      }
    ]

    Enum.each(playbooks, fn playbook_attrs ->
      case Repo.insert(%AgentMonitor.Playbook{Map.to_list(playbook_attrs)}) do
        {:ok, playbook} ->
          IO.puts("  Created playbook: #{playbook.name}")

        {:error, changeset} ->
          IO.puts("  Error creating playbook: #{inspect(changeset.errors)}")
      end
    end)
  end

  defp seed_incidents do
    IO.puts("Seeding incidents...")

    incidents = [
      %{
        title: "API Service Unavailable",
        description: "API service is returning 500 errors for all endpoints",
        status: :open,
        severity: :P1,
        assigned_to: nil
      },
      %{
        title: "Slow Database Queries",
        description: "Database response times have increased beyond acceptable thresholds",
        status: :in_progress,
        severity: :P2,
        assigned_to: "team-db"
      },
      %{
        title: "Memory Leak Detected",
        description: "Application memory usage steadily increasing over time",
        status: :open,
        severity: :P3,
        assigned_to: nil
      }
    ]

    Enum.each(incidents, fn incident_attrs ->
      case Repo.insert(%AgentMonitor.Incident{Map.to_list(incident_attrs)}) do
        {:ok, incident} ->
          IO.puts("  Created incident: #{incident.title}")

        {:error, changeset} ->
          IO.puts("  Error creating incident: #{inspect(changeset.errors)}")
      end
    end)
  end
end

AgentMonitor.Seeds.run()
