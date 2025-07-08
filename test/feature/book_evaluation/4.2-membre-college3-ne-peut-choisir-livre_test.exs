Code.require_file(Path.join(__DIR__, "_book_evaluation_methods.ex"))

defmodule LdQWeb.BookSubmissionTestsChoixLivrePerMembre2 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  import BookEvaluationMethods

  # @tag :skip
  test "Un membre de collège 3 ne peut pas choisir le livre" do
    %{parrain_id: parrain_id, procedure: procedure} = bddshot("evaluation-book/3-parrain-et-start-eval")
    membre = get_membre_with_session(not: parrain_id, min_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_three) + 1)

    # Le livre concerné par cette évaluation
    book    = get_book_of_proc(procedure)

    membre 
    |> se_connecte()
    |> rejoint_la_page("/membre/#{membre.id}") # sa page d'accueil personnelle
    |> pause(5)
    |> et_voit("h4", "Nouveaux livres à évaluer")
    |> et_ne_voit_pas("div", book.title)
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