defmodule LdQWeb.BookSubmissionTestsStep3_1 do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip 
  test "Un administrateur peut attribuer un parrain" do
    %{procedure: procedure} = bddshot("evaluation-book/2-autorisation-auteur")

    admin = make_admin() # ou renvoie celui qui existe

    admin
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(30)
  end
  
end