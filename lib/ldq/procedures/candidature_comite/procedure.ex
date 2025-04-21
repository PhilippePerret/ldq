defmodule LdQ.Procedure.CandidatureComite do
  @moduledoc """
  Module qui gère la candidature d'un postulant au comité de lecture,
  depuis la soumission de sa candidature jusqu'à son acceptation ou 
  son refus.
  """

  import LdQ.Procedure

  @steps [
    %{name: "Soumission de la candidature", fun: :start},
    %{name: "Accepter, refuser ou soumettre à un test", fun: :accepte_refuse_or_test},
    %{name: "Refus de la candidature", fun: :refuser_candidature},
    %{name: "Accepter la candidature", fun: :accepter_candidature},
    %{name: "Soumettre à un test", fun: :soumettre_a_test}
  ]

  def start(params) do
    # On doit créer une procédure pour cette candidature, procédure 
    # qui va accompagner toute la 
    data = %{
      user_id:    params["user_id"], 
      user_mail:  params["user_mail"],
      genres:     Enum.split(params["genres"]) |> Enum.map(fn g -> String.trim(g) end),
      procedure_id: nil, 
      folder:     __DIR__
    }
    user = Comptes.get_user!(params["user_id"])
    
    proc = create_procedure(%{
      proc_dim:     "candidature-comite",
      data:         data,
      steps_done:   ["start"],
      current_step: "start",
      next_step:    "accepte_refuse_or_test"
    })

    data = %{data | procedure_id: proc.id}

    mail_data = %{
      mail_id:    nil,
      procedure:  procedure,
      user:       user,
      folder:     __DIR__
    }

    send_mail(:admins, user.mail, %{mail_data | mail_id: "user-candidature-recue"})
    send_mail(user.mail, :admins, %{mail_data | mail_id: "admin-new-candidature"})
    notify(:admins, "accepte_refuse_or_test", %{
      procedure_id:     proc.id,
      notif_dim:         "accepte_refuse_or_test",
      group_target:     "admins",
      title:            "Accepter, refuser, ou demander de passer le test pour une candidature au comité de lecture",
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
        tester_candidature(params)
    end
  end

  def refuser_candidature(params) do
    procedure = get_procedure(params["procedure_id"])
    raison = if params["notif"]["raison"] == "" do "Aucune" else
      String.trim(params["notif"]["raison"])
    end
    send_mail(procedure.user.mail, :admins, "refuser-candidature-comite", procedure.data)
    delete_procedure(procedure)
  end

  def accepter_candidature(params) do
    procedure = get_procedure(params["procedure_id"])
    send_mail(procedure.user.mail, :admins, "valider-candidature-comite", procedure.data)
  end

  def soumettre_a_test(params) do
    procedure = get_procedure(params["procedure_id"])

  end

end