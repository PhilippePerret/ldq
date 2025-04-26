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



  @doc """
  Principalement appelée par la page d'administration qui affiche
  les procédures (ou celle de l'user) pour gérer les procédures
  """
  def run(procedure) when is_struct(procedure, __MODULE__) do
    proc_dim = procedure.proc_dim
    proc_path = procedure_run_path(proc_dim)
    [{module, _}] = Code.compile_file(proc_path)
    LdQ.ProcedureMethods.__run__(module, procedure)
  end


  defp procedure_run_path(proc_dim) do
    Path.join([folder_procedure(proc_dim), "run.ex"])
  end

  defp folder_procedure(proc_dim) when is_binary(proc_dim) do
    Path.join([folder_procedures(), proc_dim])
  end

  defp folder_procedures do
    Path.join(["priv", "procedures"])
  end
end