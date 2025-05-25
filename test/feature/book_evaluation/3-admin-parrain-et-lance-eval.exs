defmodule LdQWeb.BookSubmissionTestsStep3_1 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip 
  test "Un administrateur peut attribuer un parrain" do
    %{admin: admin, procedure: procedure} = bddshot("evaluation-book/2-autorisation-auteur")

  end
  
end