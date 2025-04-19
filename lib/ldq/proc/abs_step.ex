defmodule LdQ.Proc.AbsStep do
  use Ecto.Schema
  import Ecto.Changeset

  alias LdQ.Proc

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "abs_steps" do
    field :data, :map
    field :name, :string
    field :short_name, :string
    field :description, :string
    field :fonction, :string
    field :short_description, :string
    field :last, :boolean, default: false

    belongs_to :abs_proc, Proc.AbsProc

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(abs_step, attrs) do
    abs_step
    |> cast(attrs, [:name, :short_name, :fonction, :data, :short_description, :description, :abs_proc_id])
    |> validate_required([:name, :short_name, :fonction, :short_description, :abs_proc_id])
    |> assoc_constraint(:abs_proc)
  end
end
