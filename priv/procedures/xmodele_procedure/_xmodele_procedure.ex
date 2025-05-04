defmodule LdQ.Procedure.XModeleProcedure do # <========= RENSEIGNER
  @moduledoc """
  <Description de la procédure>
  """
  use LdQWeb.Procedure

  def proc_name, do: "<NOM DE LA PROCÉDURE>"
  def proc_dim,   do: "xmodule_procedure" # <========= RENSEIGNER

  @steps [
    # Liste des étapes
    # %{name: "nom humain", fun: :fonction, admin_required: false, owner_required: false}
  ]|> Enum.with_index() |> Enum.map(fn {s, index} -> Map.put(s, :index, index) end)
  def steps, do: @steps

  @doc """
  Appelée par ProcedureController.create/3 pour créer la procédure
  """
  def procedure_attributes(params) do
    user  = params.user
    owner = params.user         # <========= RENSEIGNER
    %{
      proc_dim:     proc_dim(),
      owner_type:   "user",     # <========= RENSEIGNER
      owner_id:     owner.idn,
      steps_done:   ["create"],
      next_step:    "",         # <========= RENSEIGNER
      data: %{
        user_id:    user.id,
        user_mail:  user.email,
        folder:     __DIR__
      }
    }
  end


  # ==== FONCTIONS DES ÉTAPES ====

  def fonction_etape(procedure) do
    user = get_owner(procedure)

    # Si le texte est défini dans le dossier "texte"
    load_phil_text(__DIR__, "submit_candidature", %{user: user, autres: :variables})
  end


end