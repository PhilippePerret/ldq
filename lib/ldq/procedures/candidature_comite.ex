defmodule LdQ.Procedure.CandidatureComite do

  import LdQ.Procedure

  @moduledoc """
  Module qui gère la candidature d'un postulant au comité de lecture,
  depuis la soumission de sa candidature jusqu'à son acceptation ou 
  son refus.
  """
  @id_procedure "candidature-comite"

  @steps [
    %{name: "Soumission de la candidature", fun: :on_submit_form}
  ]

  def on_submit_form(params) do
    # On doit créer une procédure pour cette candidature
    data = %{
      user_id: params["user_id"], 
      user_mail: params["user_mail"],
      genres:     Enum.split(params["genres"]) |> Enum.map(fn g -> String.trim(g) end)
    }
    Proc.create_procedure(%{
      proc_id:  @id_procedure,
      data:     data,
      steps:    [:on_submit_form]
    })
    send_mail(:admin, data.user_mail, "user-soumission-candidature")
    send_mail(data.user_mail, :admins, "admin-soumission-candidature")
    notify(:admin, :accepte_ou_refuse_candidature_comite)
  end



end