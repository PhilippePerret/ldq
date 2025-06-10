Code.require_file(Path.join(__DIR__, "_book_evaluation_methods.ex"))

defmodule LdQWeb.BookSubmissionTestsRefusParrainage do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  import BookEvaluationMethods

  # @tag :skip 
  test "Le parrain désigné voit le parrainage sur son tableau de bord" do
    %{parrain_id: parrain_id, procedure: procedure} = bddshot("evaluation-book/3-parrain-et-start-eval")
  
    book = get_book_of_proc(procedure)
    parrain = get_user_with_session(parrain_id)

    parrain
    |> rejoint_la_page("/membre/#{parrain.id}")
    |> pause(1)
    |> et_ne_voit_pas("section#new-books div.book", book.title)
    # Le parrain d'un livre appartenant au collège 3, il ne peut pas
    # évaluer le livre quand il est soumis au premier collège
    |> et_voit("h4", "Vos évaluations en cours")
    |> et_ne_voit_pas("section#evalued-books div.book", book.title, "Un membre du 3e collège NE devrait PAS voir un livre qu'il parraine, mais soumis au 1er collège, dans sa liste de livres évalués.")
    # Le livre se trouve dans sa section parrainage
    |> et_voit("h4", "Vos parrainages", "Un membre du troisième collège DOIT voir sa section Parrainages")
    |> et_voit("section#parrainages div.book", book.title)
  
  end
  
end