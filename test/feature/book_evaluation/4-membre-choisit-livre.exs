defmodule LdQWeb.BookSubmissionTestsChoixLivrePerMembre do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip 
  test "Un membre de bon niveau voit le livre et le choisit" do
    %{parrain_id: parrain_id, procedure: procedure} = bddshot("evaluation-book/3-admin-attribute-parrain-et-lance-eval")
  
    membre = get_membre_with_session(max_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_two - 1)
  
    # Son crédit augmente automatiquement
    # TODO

    membre |> se_deconnecte()

  end

  # @tag :skip
  test "Un membre de niveau supérieur ne peut pas choisir le livre" do
    # TODO Voir si ça pose encore problème comme avant, avec deux
    # session. Peut-être faut-il fermer explicitement les sessions,
    # dans ce test et le précédent, avec la fonction se_deconnecte
    membre = get_membre_with_session(min_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_two)

    membre |> se_deconnecte()

  end

  # @tag :skip
  test "Un membre du troisième collège ne peut pas choisir le livre" do
    membre = get_membre_with_session(min_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_three)

    membre |> se_deconnecte()
  end
  
end