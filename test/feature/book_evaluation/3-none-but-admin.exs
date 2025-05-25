defmodule LdQWeb.BookSubmissionTestsStep3NoneButAdmin do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip 
  test "Un visiteur quelconque ne peut pas rejoindre la procédure" do
    %{procedure: procedure} = bddshot("evaluation-book/2-autorisation-auteur")
    
  end
  
  @tag :skip 
  test "Un visiteur identifié ne peut pas rejoindre la procédure" do
    %{procedure: procedure} = bddshot("evaluation-book/2-autorisation-auteur")
    
  end
  
  @tag :skip 
  test "Un membre du comité ne peut rejoindre la procédure" do
    %{procedure: procedure} = bddshot("evaluation-book/2-autorisation-auteur")

  end
  
end