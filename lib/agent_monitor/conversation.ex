defmodule AgentMonitor.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "conversations" do
    belongs_to(:workflow, AgentMonitor.Workflow)
    field(:agent_id, :string)
    field(:role, Ecto.Enum, values: [:system, :user, :assistant])
    field(:content, :string)
    field(:metadata, :map, default: %{})
    field(:tokens, :integer)
    field(:is_summary, :boolean, default: false)
    field(:summary_of, {:array, :binary_id}, default: [])
    field(:embedding, {:array, :float})
    field(:topic, :string)

    timestamps()
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [
      :workflow_id,
      :agent_id,
      :role,
      :content,
      :metadata,
      :tokens,
      :is_summary,
      :summary_of,
      :embedding,
      :topic
    ])
    |> validate_required([:workflow_id, :agent_id, :role, :content])
    |> foreign_key_constraint(:workflow_id)
  end

  def system_message_changeset(workflow_id, content) do
    %__MODULE__{}
    |> changeset(%{
      workflow_id: workflow_id,
      agent_id: "system",
      role: :system,
      content: content
    })
  end

  def agent_message_changeset(workflow_id, agent_id, content, metadata \\ %{}) do
    %__MODULE__{}
    |> changeset(%{
      workflow_id: workflow_id,
      agent_id: agent_id,
      role: :assistant,
      content: content,
      metadata: metadata
    })
  end

  def user_message_changeset(workflow_id, content) do
    %__MODULE__{}
    |> changeset(%{
      workflow_id: workflow_id,
      agent_id: "user",
      role: :user,
      content: content
    })
  end

  def summary_changeset(workflow_id, content, message_ids) do
    %__MODULE__{}
    |> changeset(%{
      workflow_id: workflow_id,
      agent_id: "system",
      role: :system,
      content: content,
      is_summary: true,
      summary_of: message_ids
    })
  end
end
