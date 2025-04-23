defmodule LdQ.Procedure.CandidatureComite do
  @moduledoc """
  Module qui gère la candidature d'un postulant au comité de lecture,
  depuis la soumission de sa candidature jusqu'à son acceptation ou 
  son refus.
  """

  import LdQ.ProcedureMethods

  alias LdQ.Comptes

  @steps [
    %{name: "Soumission de la candidature", fun: :start},
    %{name: "Accepter, refuser ou soumettre à un test", fun: :accepte_refuse_or_test},
    %{name: "Refus de la candidature", fun: :refuser_candidature},
    %{name: "Accepter la candidature", fun: :accepter_candidature},
    %{name: "Soumettre à un test", fun: :soumettre_a_test}
  ] |> Enum.with_index() |> Enum.map(fn {s, index} -> Map.put(s, :index, index) end)



  def start(params) do
    # On doit créer une procédure pour cette candidature, procédure 
    # qui va accompagner toute la 
    IO.inspect(params, label: "Paramètres à l'entrée de #{__MODULE__}.start")

    candidat = params["candidat"]
    user = Comptes.get_user!(candidat["user_id"])

    data = %{
      user_id:      candidat["user_id"], 
      user_mail:    user.email,
      genres:       String.split(candidat["genres"], ",") |> Enum.map(fn g -> String.trim(g) end),
      procedure_id: nil, 
      folder:     __DIR__
    }
    
    proc = create_procedure(%{
      proc_dim:     "candidature-comite",
      owner_type:   "user",
      owner_id:     user.id,
      data:         data,
      steps_done:   ["start"],
      current_step: "start",
      next_step:    "accepte_refuse_or_test"
    })

    data = %{data | procedure_id: proc.id}

    mail_data = %{
      mail_id:    nil,
      procedure:  proc,
      user:       user,
      folder:     __DIR__
    }

    send_mail(:admin, user.email, %{mail_data | mail_id: "user-candidature-recue"})
    send_mail(user.email, :admins, %{mail_data | mail_id: "admin-new-candidature"})
    notify(%{
      notif_dim:      "accepte_refuse_or_test",
      procedure_id:   proc.id,
      group_target:   "admins",
      title:          "Accepter, refuser, ou demander de passer le test pour une candidature au comité de lecture",
      body:             """
      <select name="notif[action]">
        <option value="accept">Accepter la candidature</option>
        <option value="refuse">Refuser la candidature</option>
        <option value="tester">Demander à passer le test</option>
      </select>
      <label>Motif du refus</label>
      <textearea name="notif[raison]"></textarea>
      <div class="buttons"><button>Soumettre</button></div>
      """,
      data:             data,
      action_required:  true
    })
  end

  def accepte_refuse_or_test(params) do
    procedure = get_procedure(params["procedure_id"])
    case params["notif"]["action"] do
      "accept" ->
        accepter_candidature(params)
      "refuse" ->
        refuser_candidature(params)
      "tester" ->
        soumettre_a_test(params)
    end
  end

  def refuser_candidature(params) do
    procedure = get_procedure(params["procedure_id"])

    raison = if params["notif"]["raison"] == "" do "Aucune" else
      String.trim(params["notif"]["raison"])
    end
    params = params
    |> Map.put("procedure", procedure)
    |> Map.put("raison", raison)
    |> Map.put("mail_id", "user-soumission-refused")

    send_mail(procedure.user.mail, :admins, params)
    delete_procedure(procedure)
  end

  def accepter_candidature(params) do
    procedure = get_procedure(params["procedure_id"])
    params = params
    |> Map.put("procedure", procedure)
    |> Map.put("mail_id", "user-soumission-success")
    send_mail(procedure.user.mail, :admins, params)
  end

  def soumettre_a_test(params) do
    procedure = get_procedure(params["procedure_id"])
    params = params
    |> Map.put("procedure", procedure)
    |> Map.put("mail_id", "user-soumission-test")
    send_mail(procedure.user.mail, :admins, params)
  end

end