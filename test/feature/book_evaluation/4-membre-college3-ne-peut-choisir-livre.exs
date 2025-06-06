defmodule LdQWeb.BookSubmissionTestsChoixLivrePerMembre2 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  test "Un membre de collège 3 ne peut pas choisir le livre" do
    %{parrain_id: parrain_id, procedure: procedure} = bddshot("evaluation-book/3-parrain-et-start-eval")
    membre = get_membre_with_session(not: parrain_id, min_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_two))

    membre 
    |> se_connecte()
    |> pause(4)
    |> se_deconnecte()


  end

  @tag :skip
  test "Un membre du troisième collège ne peut pas choisir le livre" do
    %{parrain_id: parrain_id, procedure: procedure} = bddshot("evaluation-book/3-parrain-et-start-eval")
    membre = get_membre_with_session(not: parrain_id, min_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_three))

    membre 
    |> se_connecte()
    |> pause(4)
    |> se_deconnecte()

  end
  
end