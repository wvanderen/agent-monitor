defmodule AgentMonitor.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "attachments" do
    field(:filename, :string)
    field(:content_type, :string)
    field(:file_path, :string)
    field(:file_size, :integer)

    belongs_to(:incident, AgentMonitor.Incident)

    timestamps()
  end

  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [
      :filename,
      :content_type,
      :file_path,
      :file_size,
      :incident_id
    ])
    |> validate_required([
      :filename,
      :content_type,
      :file_path,
      :incident_id
    ])
    |> foreign_key_constraint(:incident_id)
    |> validate_number(:file_size, greater_than_or_equal_to: 0)
  end
end
