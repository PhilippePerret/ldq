defmodule LdQ.Procedure do
  use Ecto.Schema
  import Ecto.Changeset
  alias LdQ.Repo
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "procedures" do
    field :proc_dim, :string
    field :owner_type, :string
    field :owner_id, :binary
    field :current_step, :string
    field :next_step, :string
    field :steps_done, {:array, :string}
    field :data, :string

    belongs_to :submitter, LdQ.Comptes.User

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = procedure, attrs) do
    attrs = 
      attrs
      |> data_to_json()

    procedure
    |> cast(attrs, [:proc_dim, :submitter_id, :owner_type, :owner_id, :current_step, :next_step, :steps_done, :data])
    |> validate_required([:proc_dim, :submitter_id, :owner_type, :owner_id, :current_step])
  end

def data_to_json(%{"data" => data} = attrs) when is_map(data), do: %{attrs | "data" => Jason.encode!(data)}
def data_to_json(%{"data" => data} = attrs) when is_binary(data), do: attrs
def data_to_json(attrs), do: Map.put(attrs, "data", "{}")


  @doc """
  Principalement appelée par la page du contrôleur de procédure pour
  afficher le retour de la procédure.
  """
  def run(procedure) when is_struct(procedure, __MODULE__) do
    module = get_proc_module(procedure)
    LdQ.ProcedureMethods.__run__(module, procedure)
  end

  @doc """
  Retourne la procédure d'identifiant +id+
  """
  def get(proc_id) do
    proc = Repo.get!(__MODULE__, proc_id)
    %{proc | data: proc.data && Jason.decode!(proc.data)}
    |> IO.inspect(label: "PROCÉDURE RELEVÉE")
  end

  @doc """
  Retourne la liste des étapes de la procédure +procedure+

  @param {LdQ.Procedure} Instance de procédure
  """
  def get_steps_of(procedure) when is_struct(procedure, __MODULE__) do
    module = get_proc_module(procedure)
    module.steps()
  end

  @module_per_dim :module_per_dim

  @doc """
  Pour démarrer l'agent qui va conserver les modules de chaque 
  procédure par son diminutif.
  """
  def start_agent do
    Agent.start_link(fn -> %{} end, name: @module_per_dim)
  end
  def get_module_from_agent(proc_dim) do
    Agent.get(@module_per_dim, &Map.get(&1, proc_dim))
  end

  @doc """
  Retourne le module de la procédure (celui qui contient toutes les
  méthodes et constantes)
  C'est cette méthode qui charge le module si ça n'est pas encore 
  fait. Si le module est déjà chargé, il le prend dans l'agent
  """
  def get_proc_module(procedure) when is_struct(procedure, __MODULE__) do
    proc_dim = procedure.proc_dim
    get_proc_module(proc_dim)
  end
  def get_proc_module(proc_dim) when is_binary(proc_dim) do
    case get_module_from_agent(proc_dim) do
    nil     -> load_and_store_module(proc_dim)
    module  -> module
    end
  end

  # Charge le module et le consigne dans l'agent
  # @return {Module}
  defp load_and_store_module(proc_dim) do
    proc_path = procedure_run_path(proc_dim)
    [{module, _}] = Code.compile_file(proc_path)
    Agent.update(@module_per_dim, &Map.put(&1, proc_dim, module))
    module
  end

  defp procedure_run_path(proc_dim) do
    Path.join([folder_procedure(proc_dim), "_#{proc_dim}.ex"])
  end

  def folder_procedure(proc_dim) when is_binary(proc_dim) do
    Path.join([folder_procedures(), proc_dim])
  end

  def folder_procedures do
    Path.join(["priv", "procedures"])
  end
end