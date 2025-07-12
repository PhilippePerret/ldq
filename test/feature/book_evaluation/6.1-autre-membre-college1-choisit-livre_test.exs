Code.require_file(Path.join(__DIR__, "_book_evaluation_methods.ex"))

defmodule LdQWeb.BookSubmissionTestsChoixLivrePerAutreMembreCollege1 do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers, only: [bddshot: 1, bddshot: 2, pause: 2]
  import FeaturePublicMethods
  import BookEvaluationMethods

  test "Un autre membre du collège 1 voit les livres et peut choisir le nouveau livre" do
    #
    # - PHOTOGRAPHIE -
    # Ce test produit la photographie "evaluation-book/6-autre-membre-college1-choisit-livre"
    # Note : dans ce test, le livre a de nouveau un parrain.
    # 
    %{procedure: procedure, membre_id: membre_id} = bddshot("evaluation-book/4-parrain-a-refuse-parrainage")

    # On prend un membre du collège 1
    membre2 = get_membre_with_session(max_credit: LdQ.Evaluation.Numbers.points_for(:seuil_college_two) - 1)
  
    book = get_book_of_proc(procedure)

    membre2 
    |> rejoint_la_page("/membre/#{membre2.id}") # sa page d'accueil personnelle
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

    # Le parrain doit avoir été averti qu'un nouveau membre du 
    # collège 1 avait choisi le livre
    # TODO

    bddshot("evaluation-book/6-autre-membre-college1-choisit-livre", %{
      procedure_id: procedure.id,
      membre_id: membre_id,
      autre_membre_id: membre.id
    })
  end

end