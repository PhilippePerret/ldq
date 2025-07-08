Code.require_file(Path.join(__DIR__, "_book_evaluation_methods.ex"))

defmodule LdQWeb.BookSubmissionTestsChoixLivrePerMembre1 do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers, only: [bddshot: 1, bddshot: 2, pause: 2]
  import FeaturePublicMethods
  import BookEvaluationMethods

  # @tag :skip
  test "Un membre du collège 1 voit les livres et peut choisir le nouveau livre" do
    #
    # - PHOTOGRAPHIE -
    # Ce test produit la photographie "evaluation-book/5-membre-college1-choisit-livre"
    # Dans ce test, un membre du collège 1 choisit le nouveau livre à évaluer
    # 10 autres livres à évaluer sont également créés.
    # Note : dans ce test, le livre n'a pas de parrain.
    # 
    %{procedure: procedure} = bddshot("evaluation-book/4-parrain-a-refuse-parrainage")

    # On fait des livres à évaluer pour qu'il y en ait d'autres
    books = make_books(count: 10, current_phase: [20, 21])
    
    # On prend un membre du collège 1
    membre = get_membre_with_session(max_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_two) - 1)
  
    # book = Enum.at(books, 3)
    book = get_book_of_proc(procedure)

    membre 
    |> rejoint_la_page("/membre/#{membre.id}") # sa page d'accueil personnelle
    |> et_voit("h4", "Nouveaux livres à évaluer")
    |> et_voit("div.book", Enum.at(books, 0).title)
    |> et_voit("div.book", book.title)
    # Il clique sur le 4e livre
    |> et_voit("section#new-books div.title", book.title)
    |> clique_le_lien("btn-eval-#{book.id}")
    |> pause(1)
    # Le livre ne se trouve plus dans sa section de livre à choisir
    |> et_ne_voit_pas("section#new-books div.title", book.title)
    # Le livre se retrouve dans sa section de livre à évaluer
    |> et_voit("section#evalued-books", book.title)
    |> pause(1)
    # Un membre du collège 1 ne doit pas pouvoir voir sa section parrainage
    |> et_ne_voit_pas("h4", "Vos parrainages", "Un membre du premier collège NE devrait PAS voir de section Parrainages")
    |> se_deconnecte()

    # - Vérifications -

    # Son crédit augmente automatiquement
    # TODO

    # Le parrain (ancien) ne doit pas avoir été averti et aucun
    # parrain ne doit avoir été prévenu
    # TODO

    bddshot("evaluation-book/5-membre-college1-choisit-livre", %{
      procedure_id: procedure.id,
      membre_id: membre.id
    })
  end

  @tag :skip
  test "Un nombre défini de membres du collège 1 prenant le livre le passe véritablement en évaluation" do
    
    # Avant que les x lecteurs aient été définis, il doit exister un 
    # trigger pour s'assurer que ce quorum sera atteint (placé au 
    # moment où l'administrateur met le livre en évaluation).
    # (à la fin de cette procédure il aura été détruit)
    # TODO

    # Un trigger temporel a été implanté pour se déclencher à un 
    # certain moment pour que le livre ne reste pas bloqué par 
    # quelques notes (=> solicitation des membres)
    # TODO

    # Le trigger temporel d'attente de x lecteurs doit avoir été
    # détruit
    # TODO

  end
end