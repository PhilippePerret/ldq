defmodule LdQ.Evaluation.CreditCalculator do
  @moduledoc """
  Module qui gère tout ce qui relève de l'évaluation du livre u 
  niveau du calcul des points, des classements, etc.
  """

  # Table de l'attribution des points en fonction de l'opération
  # On peut obtenir une valeur de l'extérieur grâce à la fonction
  # api points_for/1 qui doit recevoir la clé
  @points_per_operation %{
    parrainage:           15,
    refus_parrainage:     -10,
    fiche_lecture_qcm:    15,
    real_fiche_lecture:   10, # par milliers de caractères
  }


  @doc """
  Retourne le nombre de points accordés pour l'opération 
  d'identifiant +op_id+

  @param {Atom} op_id Identifiant de l'opération dans @points_per_operation

  @return {Integer} Le nombre de points
  """
  def points_for(op_id) when is_atom(op_id) and not is_nil(op_id) do
    @points_per_operation[op_id]
  end

end