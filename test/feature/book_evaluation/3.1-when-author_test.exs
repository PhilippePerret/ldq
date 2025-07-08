defmodule LdQWeb.BookSubmissionTestsStep3WhenAuthor do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip 
  test "L'auteur trouve une page d'attente" do
    %{author: author, procedure: procedure} = bddshot("evaluation-book/2-autorisation-auteur")
    user = 
      LdQ.Comptes.get_user!(author.user_id)
      |> Map.put(:password, "passepartout")

    user
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(1)
  end
  
end