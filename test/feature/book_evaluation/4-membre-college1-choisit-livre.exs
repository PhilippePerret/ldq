defmodule LdQWeb.BookSubmissionTestsChoixLivrePerMembre1 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  test "Un membre collège 1 voit les livres et peut en choisir" do
    # TODO Voir si ça pose encore problème comme avant, avec deux
    # session. Voir si la fermeture explicite des sessions est 
    # efficace.,
    # Si c'est le cas, on pourra renommmer ce test :
    #   "4-membres-choisissent-livre.ex"
    # 
    %{parrain_id: _parrain_id, procedure: _procedure} = bddshot("evaluation-book/3-attribution-parrain")
  
    books = make_books(count: 10, current_phase: [20, 21])
    membre = get_membre_with_session(max_credit: LdQ.Evaluation.CreditCalculator.points_for(:seuil_college_two) - 1)
  
    # Son crédit augmente automatiquement
    # TODO

    book = Enum.at(books, 3)

    membre 
    |> rejoint_la_page("/membre/#{membre.id}") # sa page d'accueil personnelle
    |> et_voit("h4", "Nouveaux livres à évaluer")
    |> et_voit("div", Enum.at(books, 0).title)
    |> clique_le_lien("btn-eval-#{book.id}")
    |> pause(40)
    |> se_deconnecte()

  end

end