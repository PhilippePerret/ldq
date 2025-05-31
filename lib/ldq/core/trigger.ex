defmodule LdQ.Core.Trigger do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "triggers" do
    field :type, :string
    field :uniq_scope, :string
    field :trigger_at, :naive_datetime
    field :data, :string
    field :marked_by, :binary_id
    field :priority, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trigger, attrs) do
    trigger
    |> cast(attrs, [:type, :data, :uniq_scope, :trigger_at, :priority, :marked_by])
    |> validate_required([:type, :data, :uniq_scope, :trigger_at, :priority])
    |> unique_constraint(:uniq_scope)
  end
end
