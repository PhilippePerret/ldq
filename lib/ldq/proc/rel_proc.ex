defmodule LdQ.Proc.RelProc do
  use Ecto.Schema
  import Ecto.Changeset

  alias LdQ.Proc

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rel_procs" do
    field :status, :integer
    field :owner_id, :binary
    
    # field :followed_by, :binary_id
    belongs_to :followed_user, LdQ.Comptes.User, foreign_key: :followed_by
    
    # field :abs_proc_id, :binary_id
    belongs_to :abs_proc, Proc.AbsProc
    has_many :rel_steps, Proc.RelStep

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(rel_proc, attrs) do
    rel_proc
    |> cast(attrs, [:owner_id, :status, :abs_proc_id, :followed_by])
    |> validate_required([:owner_id, :status, :followed_by])
    |> assoc_constraint(:abs_proc)
    |> assoc_constraint(:followed_user)
  end
end
