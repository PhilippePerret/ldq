defmodule LdQWeb.ProcedureController do
  use LdQWeb, :controller

  import Ecto.Query, only: [from: 2]
  alias LdQ.Repo
  import LdQ.ProcedureMethods

  @doc """
  Pour créer une nouvelle procédure

  C'est la fonction qui est appelée par le lien /proc/new/<proc dim>
  """
  def create(conn, %{"proc_dim" => proc_dim} = params) do
    cur_user = conn.assigns.current_user
    params = params |> Map.merge(%{user: cur_user})
    module = LdQ.Procedure.get_proc_module(proc_dim)
    proc_attrs = 
      module.procedure_attributes(params)
      |> Map.put(:submitter_id, cur_user.id)
    # On doit empêcher de faire deux fois la même procédure à peu
    # d'intervalle près
    procedure =
      case submitted_soon_ago(proc_attrs) do
      nil -> 
        create_procedure(proc_attrs)
      proc -> 
        proc
      end
      
    procedure = procedure |> fill_procedure(params, module)
    run_avec_autorisation(conn, procedure, params)
  end

  # Retourne la procédure enregistrée si elle date d'il y a moins 
  # d'une heure.
  defp submitted_soon_ago(proc_attrs) do
    ilya_une_heure = NaiveDateTime.add(NaiveDateTime.utc_now(), - 1, :hour)
    from(p in LdQ.Procedure, where: p.proc_dim == ^proc_attrs.proc_dim and p.submitter_id == ^proc_attrs.submitter_id and p.inserted_at > ^ilya_une_heure)
    |> Repo.all()
    |> Enum.at(-1)
  end

  @doc """
  On ajoute quelques données à la map procédure, par exemples les
  paramètres et le nom humain de la procédure.
  """
  def fill_procedure(procedure, params, module \\ nil) do
    module = 
      if is_nil(module) do
        LdQ.Procedure.get_proc_module(procedure.proc_dim)
      else 
        module 
      end
    procedure 
    |> Map.put(:params, params)
    |> Map.put(:name,  module.proc_name())
    |> Map.put(:user,  LdQ.ProcedureMethods.get_owner(procedure))
    |> transform_data_if_required()
    |> add_procedure_own_properties(module)
  end

  # Fonction qui s'assure que la propriété :data soit bien dejsonnées
  defp transform_data_if_required(procedure) do
    cond do
      is_nil(Map.get(procedure, :data, nil)) -> procedure
      is_binary(procedure.data) -> %{procedure | data: Jason.decode!(procedure.data)}
      true -> procedure
    end
  end

  # Si une fonction :defaultize_procedure/1 existe, il faut la jouer
  # pour ajouter les propriétés propres à la procédure en question
  defp add_procedure_own_properties(procedure, module) do
    IO.inspect(procedure, label: "Procédure dans add_procedure_own_properties")
    if function_exported?(module, :defaultize_procedure, 1) do
      apply(module, :defaultize_procedure, [procedure])
    else 
      procedure 
    end
  end


  @doc """
  Joue la prochaine étape de la procédure d'identifiant +proc_id+
  Cette étape peut être définie dans l'enregistrement de la procédure
  si c'est la prochaine naturelle, ou dans le paramètre "nstep" quand
  il faut la définir explicitement.

  @param
  """
  def run(conn, %{"proc_id" => proc_id} = params) do
    # IO.puts "-> run procédure #{proc_id}"
    procedure = get_procedure(proc_id)

    # Procédure inexistante
    if is_nil(procedure) do
      conn
      |> render(:unknown_procedure, proc_id: proc_id)
    else
      # Quand la procédure a été trouvée
      
      # On ajoute quelques valeurs
      procedure = procedure 
      |> fill_procedure(params)
      |> Map.put(:current_user, conn.assigns.current_user)
      
      # Y a-t-il une étape spécifiée ?
      procedure = 
        if is_nil(params["nstep"]) do procedure else
          Map.put(procedure, :next_step, params["nstep"])
        end

      # Barrière utilisateur. En fonction de l'étape, il faut un
      # administrateur ou le propriétaire de la procédure.
      run_avec_autorisation(conn, procedure, params)
    end
  end

  @doc """
  L'utilisateur courant doit être autorisé à jouer l'étape courante
  de la procédure +procedure+
  """
  def run_avec_autorisation(conn, procedure, _params) do
    case current_user_can_run_step?(conn.assigns.current_user, procedure) do
    true ->
      render(conn, :procedure, procedure: procedure)
    false ->
      render(conn, :require_admin, procedure: procedure)
    end
  end

end