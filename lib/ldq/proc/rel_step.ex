defmodule LdQ.Proc.RelStep do
  use Ecto.Schema
  import Ecto.Changeset

  alias LdQ.Proc

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rel_steps" do
    field :status, :integer
    field :resultat, :map
    field :abs_step_id, :binary_id
    # field :rel_proc_id, :binary_id
    belongs_to :rel_proc, Proc.RelProc

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rel_step, attrs) do
    rel_step
    |> cast(attrs, [:status, :resultat, :abs_step_id, :rel_proc_id])
    |> assoc_constraint(:rel_proc)
    |> validate_required([:abs_step_id, :status])
  end
end
