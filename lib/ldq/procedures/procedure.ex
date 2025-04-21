defmodule LdQ.Procedure do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "procedures" do
    field :proc_dim, :string
    field :owner_type, :string
    field :owner_id, :binary
    field :current_step, :string
    field :next_step, :string
    field :steps_done, {:array, :string}
    field :data, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = procedure, attrs) do
    procedure
    |> cast(attrs, [:proc_dim, :owner_type, :owner_id, :current_step, :next_step, :steps_done, :data])
    |> validate_required([:proc_dim, :owner_type, :owner_id, :current_step, :data])
  end

end