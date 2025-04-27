defmodule LdQWeb.ProcedureController do
  use LdQWeb, :controller

  import LdQ.ProcedureMethods

  @doc """
  Pour créer une nouvelle procédure

  C'est la fonction qui est appelée par le lien /proc/new/<proc dim>
  """
  def create(conn, %{"proc_dim" => proc_dim} = _params) do
    raise "Je dois apprendre à créer la procédure"
  end

  @doc """
  Joue la prochaine étape de la procédure d'identifiant +proc_id+
  Cette étape peut être définie dans l'enregistrement de la procédure
  si c'est la prochaine naturelle, ou dans le paramètre "nstep" quand
  il faut la définir explicitement.

  @param
  """
  def run(conn, %{"proc_id" => proc_id} = params) do
    procedure = 
    get_procedure(proc_id)
    |> Map.put(:params, params)
    
    # Y a-t-il une étape spécifiée ?
    procedure = 
      if is_nil(params["nstep"]) do procedure else
        Map.put(procedure, :next_step, params["nstep"])
      end
    
    # Barrière utilisateur. En fonction de l'étape, il faut un
    # administrateur ou le propriétaire de la procédure.
    case current_user_can_run_step?(conn.assigns.current_user, procedure) do
    true ->
      render(conn, :procedure, procedure: procedure)
    false ->
      render(conn, :require_admin, procedure, procedure)
    end
  end

end