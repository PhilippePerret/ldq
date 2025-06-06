defmodule LdQWeb.BookSubmissionTestsStep2 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers, except: [now: 0]
  import FeaturePublicMethods


  # @tag :skip
  @tag :admin
  test "Un administrateur trouve le texte d'attente" do
    %{admin: admin, procedure: procedure} = bddshot("evaluation-book/1-book-just-submitted")
    
    admin = get_user_with_session(admin)
    
    admin
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(4)
    |> et_voit("attend confirmation de sa soumission")
    |> end_session()
  end


end