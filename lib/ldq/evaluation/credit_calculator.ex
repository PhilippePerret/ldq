defmodule LdQ.Evaluation.CreditCalculator do
  @moduledoc """
  Module qui gère tout ce qui relève de l'évaluation du livre u 
  niveau du calcul des points, des classements, etc.
  """

  # Table de l'attribution des points en fonction de l'opération
  # On peut obtenir une valeur de l'extérieur grâce à la fonction
  # api points_for/1 qui doit recevoir la clé
  @points_per_operation %{
    parrainage:                 15,
    refus_parrainage:           -10,

    # Évaluations
    book_evaluation_college1:   10,
    book_evaluation_college2:   10,
    book_evaluation_college3:   10,

    # Fiches de lecture
    fiche_lecture_qcm:          15,
    real_fiche_lecture:         10, # par milliers de caractères

    # Nombre de crédit minimum pour appartenir au collège deux
    # TODO Ces valeurs doivent bouger, au début, jusqu'à ce 
    # qu'on atteigne un nombre de lecteur suffisant dans chaque
    # niveau
    seuil_college_two:    200,
    seuil_college_three:  500
  }


  @doc """
  Retourne le nombre de points accordés pour l'opération 
  d'identifiant +op_id+

  ## Examples

    iex> LdQ.Evaluation.CreditCalculator.points_for(:fiche_lecture_qcm)
    @points_per_operation[:fiche_lecture_qcm]

  @param {Atom} op_id Identifiant de l'opération dans @points_per_operation

  @return {Integer} Le nombre de points
  """
  def points_for(op_id) when is_atom(op_id) and not is_nil(op_id) do
    @points_per_operation[op_id]
  end

end