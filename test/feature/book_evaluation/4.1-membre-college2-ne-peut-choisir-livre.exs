Code.require_file(Path.join(__DIR__, "_book_evaluation_methods.ex"))
defmodule LdQWeb.BookSubmissionTestsChoixLivrePerMembre2 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods
  import BookEvaluationMethods

  # @tag :skip
  test "Un membre de collège 2 ne peut pas choisir le livre" do
    %{parrain_id: parrain_id, procedure: procedure} = bddshot("evaluation-book/3-parrain-et-start-eval")
    membre = get_membre_with_session(not: parrain_id, min_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_two) + 1, max_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_three) - 1)

    # Le livre concerné par cette évaluation
    book    = get_book_of_proc(procedure)

    membre 
    |> se_connecte()
    |> rejoint_la_page("/membre/#{membre.id}") # sa page d'accueil personnelle
    |> pause(1)
    |> et_voit("h4", "Nouveaux livres à évaluer")
    |> et_ne_voit_pas("div", book.title)
    # Un membre du collège 2 ne doit pas pouvoir voir sa section parrainage
    |> et_ne_voit_pas("h4", "Vos parrainages", "Un membre du second collège NE devrait PAS voir de section Parrainages")
    |> se_deconnecte()


  end
  
end