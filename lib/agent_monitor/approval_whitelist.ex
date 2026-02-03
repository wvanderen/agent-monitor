defmodule AgentMonitor.ApprovalWhitelist do
  @moduledoc """
  Schema for pre-approving certain agents, actions, or incident types.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "approval_whitelist" do
    field(:agent_id, :string)
    field(:incident_type, :string)
    field(:risk_level, :string)
    field(:action_pattern, :string)
    field(:expires_at, :utc_datetime)
    field(:created_by, :string)

    timestamps()
  end

  def changeset(whitelist_entry, attrs) do
    whitelist_entry
    |> cast(attrs, [
      :agent_id,
      :incident_type,
      :risk_level,
      :action_pattern,
      :expires_at,
      :created_by
    ])
    |> validate_required([:created_by])
    |> validate_expiration()
  end

  defp validate_expiration(changeset) do
    expires_at = get_change(changeset, :expires_at)

    if expires_at do
      if DateTime.compare(expires_at, DateTime.utc_now()) == :lt do
        add_error(changeset, :expires_at, "expiration date must be in the future")
      else
        changeset
      end
    else
      changeset
    end
  end

  def is_expired?(whitelist_entry) do
    if whitelist_entry.expires_at do
      DateTime.compare(whitelist_entry.expires_at, DateTime.utc_now()) == :lt
    else
      false
    end
  end
end
