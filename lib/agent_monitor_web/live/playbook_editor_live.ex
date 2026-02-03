defmodule AgentMonitorWeb.PlaybookEditorLive do
  use AgentMonitorWeb, :live_view

  alias AgentMonitor.Playbook

  @impl true
  def mount(_params, _session, socket) do
    playbook = %AgentMonitor.Playbook{
      name: "",
      description: "",
      steps: []
    }

    socket =
      assign(socket,
        playbook: playbook,
        step_name: "",
        step_agent: "monitor_agent",
        step_instructions: "",
        step_requires_approval: false
      )

    {:ok, socket}
  end

  @impl true
  def mount(%{"id" => playbook_id}, _session, socket) do
    playbook = AgentMonitor.Repo.get!(AgentMonitor.Playbook, playbook_id)

    socket =
      assign(socket,
        playbook: playbook,
        step_name: "",
        step_agent: "monitor_agent",
        step_instructions: "",
        step_requires_approval: false
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("add_step", %{}, socket) do
    new_step = %{
      "agent" => socket.assigns.step_agent,
      "instructions" => socket.assigns.step_instructions,
      "requires_approval" => socket.assigns.step_requires_approval
    }

    socket =
      socket
      |> assign(
        playbook:
          Map.update!(socket.assigns.playbook, :steps, fn steps -> steps ++ [new_step] end),
        step_name: "",
        step_agent: "monitor_agent",
        step_instructions: "",
        step_requires_approval: false
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("remove_step", %{"index" => index_str}, socket) do
    index = String.to_integer(index_str)

    steps = List.delete_at(socket.assigns.playbook.steps, index)

    socket = assign(socket, playbook: Map.put(socket.assigns.playbook, :steps, steps))

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{}, socket) do
    playbook = socket.assigns.playbook

    attrs = %{
      name: playbook.name,
      description: playbook.description,
      incident_type: playbook.incident_type,
      steps: playbook.steps,
      variables: playbook.variables || []
    }

    case AgentMonitor.Repo.update(Playbook.changeset(playbook, attrs)) do
      {:ok, _updated_playbook} ->
        {:noreply, put_flash(socket, :info, "Playbook saved successfully")}

      {:error, changeset} ->
        {:noreply,
         put_flash(socket, :error, "Failed to save playbook: #{inspect(changeset.errors)}")}
    end
  end
end
