defmodule LdQWeb.ProcedureController do
  @moduledoc ~S"""
  Controlleur gérant les procédures, c'est-à-dire les recevant et les traitant.
  """
  use LdQWeb, :controller

  import Ecto.Query, only: [from: 2]
  alias LdQ.Repo
  import LdQ.ProcedureMethods

  @doc ~S"""
  Fonction recevant la route `/proc/new/<proc_dim>` pour créer la procédure voulue après confirmation. Ici, on s'assure donc :

  1. Que l'utilisateur peut accomplir la démarche voulue
  2. Confirme qu'elle veut vraiment le faire.

  NOTE : Plutôt que de reprogrammer une méthode `confirme_procedure` qui sera en gros toujours la même : vérifier que l'user soit identifié et confirmer l'opération (dont il suffirait de connaitre le nom humain — qu'on peut connaitre en chargeant le module — on pourrait tout faire ici.)
  """
  def newp(conn, %{"proc_dim" => proc_dim} = params) do
    module = LdQ.Procedure.get_proc_module(proc_dim)
    # IO.inspect(module.proc_name, label: "Module")
    curuser = conn.assigns.current_user
    template =
    if is_nil(curuser) do
      :login_required
    else
      :confirmation
    end
    render(conn, template, procedure: module.proc_name, proc_dim: proc_dim, user: curuser)
  end

  @doc """
  Pour créer une nouvelle procédure

  Ce n'est plus la fonction appelée par le lien `/proc/new/<proc dim>`, car on ne doit pas créer tout de suite la procédure sans savoir qu'il faut vraiment la faire. Par exemple, lorsqu'un user veut se proposer pour le comité de lecture, on doit d'abord s'assurer qu'il est inscrit et qu'il veut réellement faire ça. Après confirmation, on passe par ici pour déclencher la procédure.

  Si l'user n'a pas coché la case d'acceptation des CGU et le captcha, il doit recommencer l'opération.
  """
  def create(conn, %{"proc_dim" => proc_dim} = params) do
    # IO.inspect(params, label: "\nPARAMS")
    form_data = params["f"]
    captcha_is_valide = Html.Form.captcha_valid?(form_data)
    cgu_are_approuved = form_data["cgu"] == "accepted"
    case cgu_are_approuved and captcha_is_valide do
    true -> do_create(conn, params)
    false ->
      errors = []
      errors = if captcha_is_valide do errors else
        errors ++ ["Merci de répondre au captcha pour prouver que vous êtes humain."] 
      end
      errors = if cgu_are_approuved do errors else
        errors ++ ["Merci d’appouver les CGU afin de passer à la suite."]
      end
      errors = errors |> Enum.join("")
      conn = put_flash(conn, :error, errors)
      redirect(conn, to: ~p"/proc/new/#{proc_dim}")
    end
  end

  def do_create(conn, %{"proc_dim" => proc_dim} = params) do

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
  On ajoute quelques données à la map procédure, par exemples les paramètres et le nom humain de la procédure.
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
    # IO.inspect(procedure, label: "Procédure dans add_procedure_own_properties")
    if function_exported?(module, :defaultize_procedure, 1) do
      apply(module, :defaultize_procedure, [procedure])
    else 
      procedure 
    end
  end


  @doc """
  Joue la prochaine étape de la procédure d'identifiant +proc_id+.
  
  Cette étape peut être définie dans l'enregistrement de la procédure si c'est la prochaine naturelle, ou dans le paramètre "nstep" quand il faut la définir explicitement.

  @param
  """
  def run(conn, %{"proc_id" => proc_dim} = params) do
    IO.inspect(params, label: "\nparams")
    form_data = params["f"]
    captcha_absent_or_valide = 
      is_nil(form_data["captcha"]) or Html.Form.captcha_valid?(form_data)
    case captcha_absent_or_valide do
    true ->
      # Quand c'est bon
      ok_run(conn, params)
    false ->
      # Quand le captcha n'a pas été founi ou qu'il est faux
      errors = "Merci de répondre au captcha pour prouver que vous êtes humain."
      conn = put_flash(conn, :error, errors)
      redirect(conn, to: ~p"/proc/#{proc_dim}")
    end
  end

  # Finalement jouée quand le captcha a été fourni
  defp ok_run(conn, %{"proc_id" => proc_id} = params) do
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
  L'utilisateur courant doit être autorisé à jouer l'étape courante de la procédure +procedure+.

  On définit cette autorisation dans la définition des étapes de la procédure, dans `@steps` qu'on peut trouver dans le fichier `steps.ex` de la procédure.
  """
  def run_avec_autorisation(conn, procedure, _params) do
    case current_user_can_run_step(conn.assigns.current_user, procedure) do
    true ->
      render(conn, :procedure, procedure: procedure)
    :not_admin ->
      render(conn, :require_admin, procedure: procedure)
    :not_owner ->
      render(conn, :require_owner, procedure: procedure)
    :impasse ->
      render(conn, :impasse)
    end
  end

end