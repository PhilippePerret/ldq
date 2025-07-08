Code.require_file(Path.join(__DIR__, "_book_evaluation_methods.ex"))

defmodule LdQWeb.BookSubmissionTestsRefusParrainage do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers, only: [bddshot: 1, bddshot: 2, pause: 2]
  import FeaturePublicMethods #, except: [now: 0]

  import BookEvaluationMethods

  # @tag :skip 
  test "Le parrain désigné refuse le parrainage du livre" do
    %{parrain_id: parrain_id, procedure: procedure} = bddshot("evaluation-book/3-parrain-et-start-eval")
  
    book = get_book_of_proc(procedure)
    # |> IO.inspect(label: "BOOK AU DÉBUT")
    parrain = get_user_with_session(parrain_id)
    ancien_credit = parrain.credit

    point_test = now()

    parrain
    |> rejoint_la_page("/membre/#{parrain.id}")
    |> pause(1)
    |> et_voit("h4", "Vos parrainages")
    |> et_voit("section#parrainages div.book", book.title)
    # Il trouve un lien pour refuser le parrainage
    |> et_voit("section#parrainages a", %{id: "btn-refus-parrainage-#{book.id}"})
    # - Test -
    # Il clique le lien pour refuser le parrainage
    |> clique_le_lien("refuser")

    # - Vérification -

    book = get_book_of_proc(procedure)
    # |> IO.inspect(label: "BOOK À LA FIN")
    # Le livre n'est plus attribué (au membre)
    assert(is_nil(book.parrain_id), "Le livre ne devrait plus être attribué à un parrain. Or, le livre est attribué à #{book.parrain_id}")
  
    # Les points ont été retirés au membre parrain
    parrain = get_user(parrain_id)
    nouveau_credit = ancien_credit - LdQ.Evaluation.CreditCalculator.points_for(:parrainage)
    assert(parrain.credit == nouveau_credit, "Le parrain devrait avoir perdu les points de son parrainage.")

    # L'administrateur a reçu un mail pour l'avertir
    admin = get_admin()
    admin
    |> recoit_un_mail(%{after: point_test, mail_id: "refus-parrainage", sender: parrain.email})

    bddshot("evaluation-book/4-parrain-a-refuse-parrainage", %{
      procedure: procedure,
      book_id: book.id,
      old_parrain_id: parrain.id
    })
  end
  
end