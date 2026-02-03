defmodule AgentMonitorWeb.Helpers do
  @moduledoc """
  Helper functions for LiveView templates.
  """

  def status_bg_color(:pending), do: "bg-gray-100 text-gray-800"
  def status_bg_color(:in_progress), do: "bg-blue-100 text-blue-800"
  def status_bg_color(:completed), do: "bg-green-100 text-green-800"
  def status_bg_color(:failed), do: "bg-red-100 text-red-800"
  def status_bg_color(:open), do: "bg-green-100 text-green-800"
  def status_bg_color(:resolved), do: "bg-purple-100 text-purple-800"
  def status_bg_color(:closed), do: "bg-gray-100 text-gray-800"
  def status_bg_color(:reopened), do: "bg-yellow-100 text-yellow-800"

  def severity_bg_color(:P1), do: "bg-red-100 text-red-800"
  def severity_bg_color(:P2), do: "bg-orange-100 text-orange-800"
  def severity_bg_color(:P3), do: "bg-yellow-100 text-yellow-800"
  def severity_bg_color(:P4), do: "bg-green-100 text-green-800"

  def role_badge(:system), do: "bg-purple-100 text-purple-800"
  def role_badge(:user), do: "bg-blue-100 text-blue-800"
  def role_badge(:assistant), do: "bg-green-100 text-green-800"

  def workflow_progress(%{steps: steps, current_step: current_step}) do
    total_steps = max(length(steps), 1)
    completed = min(current_step, total_steps)
    round(completed / total_steps * 100)
  end

  def workflow_progress(_workflow), do: 0
end
