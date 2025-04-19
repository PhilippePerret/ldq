defmodule LdQ.Proc.AbsProc do
  use Ecto.Schema
  import Ecto.Changeset

  alias LdQ.Proc

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "abs_procs" do
    field :name, :string
    field :owner_type, :string
    field :description, :string
    field :short_name, :string
    field :steps, {:array, :string}
    field :short_description, :string

    has_many :rel_procs, Proc.RelProc

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(abs_proc, attrs) do
    abs_proc
    |> cast(attrs, [:name, :short_name, :owner_type, :steps, :short_description, :description])
    |> validate_required([:name, :short_name, :owner_type, :steps, :short_description, :description])
  end
end
