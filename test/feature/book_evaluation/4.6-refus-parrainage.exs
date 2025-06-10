defmodule LdQWeb.BookSubmissionTestsRefusParrainage do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  @tag :skip 
  test "Le parrain désigné refuse le parrainage du livre" do
    %{parrain_id: parrain_id, procedure: procedure} = bddshot("evaluation-book/3-admin-attribute-parrain-et-lance-eval")
  
  
  end
  
end