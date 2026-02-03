defmodule AgentMonitor.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "comments" do
    field(:content, :string)
    field(:author, :string)

    belongs_to(:incident, AgentMonitor.Incident)

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :author, :incident_id])
    |> validate_required([:content, :author])
    |> foreign_key_constraint(:incident_id)
  end
end
