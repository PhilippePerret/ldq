defmodule LdQWeb.BookSubmissionTestsStep2_2 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  @tag :author
  test "Après soumission, l'auteur du livre peut venir confirmer la soumission" do
    %{user: user, procedure: procedure, point_test: point_test} = bdd_load("book-just-submitted")
    # IO.inspect(test_data, label: "Données du test")
    # |> IO.inspect(label: "La procédure")

    author = get_author(procedure.data["author_id"])
    author_as_user = start_session(author.user, [])
    user = get_user_with_session(user)
    # Map.put(author_as_user, :password, "passepartout")
    Map.put(user, :password, "passepartout")
    |> IO.inspect(label: "User pour connexion")
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(4)
    |> et_voit("h3", "Confirmation de la soumission du livre")

  end

end