defmodule LdQWeb.BookSubmissionTestsStep2 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods


  # @tag :skip
  test "Un administrateur trouve le texte d'attente" do
    %{admin: admin, procedure: procedure, point_test: point_test} = bdd_load("book-just-submitted")
    
    admin = get_user_with_session(admin)
    
    admin
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(1)
    |> et_voit("attend confirmation de sa soumission")
    |> end_session()
  end


end