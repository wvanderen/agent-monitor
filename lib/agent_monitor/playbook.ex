defmodule AgentMonitor.Playbook do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "playbooks" do
    field(:name, :string)
    field(:description, :string)
    field(:incident_type, :string)
    field(:service, :string)
    field(:variables, {:array, :map}, default: [])
    field(:steps, {:array, :map}, default: [])
    field(:version, :string, default: "1.0.0")
    field(:is_active, :boolean, default: true)
    field(:author, :string)

    has_many(:incidents, AgentMonitor.Incident)
    has_many(:workflows, AgentMonitor.Workflow)

    timestamps()
  end

  def changeset(playbook, attrs) do
    playbook
    |> cast(attrs, [
      :name,
      :description,
      :incident_type,
      :service,
      :variables,
      :steps,
      :version,
      :is_active,
      :author
    ])
    |> validate_required([:name, :incident_type])
    |> validate_version_format()
  end

  defp validate_version_format(changeset) do
    case get_change(changeset, :version) do
      nil ->
        changeset

      version ->
        if Regex.match?(~r/^\d+\.\d+\.\d+$/, version) do
          changeset
        else
          add_error(changeset, :version, "must be in semantic version format (e.g., 1.0.0)")
        end
    end
  end

  def fork_changeset(original, author) do
    %__MODULE__{}
    |> changeset(%{
      name: "#{original.name} (fork)",
      description: original.description,
      incident_type: original.incident_type,
      service: original.service,
      variables: original.variables,
      steps: original.steps,
      version: "1.0.0",
      is_active: true,
      author: author
    })
  end

  def update_version_changeset(playbook, new_version) do
    change(playbook, version: new_version)
  end

  def interpolate_variables(playbook, values) do
    variable_map = Map.new(playbook.variables, fn v -> {v["name"], v["default_value"]} end)
    variable_map = Map.merge(variable_map, values)

    Enum.map(playbook.steps, fn step ->
      Map.update!(step, "instructions", fn instructions ->
        Enum.reduce(variable_map, instructions, fn {key, value}, acc ->
          String.replace(acc, "{{#{key}}}", to_string(value))
        end)
      end)
    end)
  end

  def get_workflow_chain(playbook, variable_values \\ %{}) do
    playbook
    |> interpolate_variables(variable_values)
    |> Enum.map(fn step -> String.to_atom(step["agent"]) end)
  end
end
