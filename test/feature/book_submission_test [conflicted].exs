defmodule LdQWeb.BookSubmissionTests do
  @moduledoc """
  Module de test permettant de tester la soumission d'un livre en 
  mode intégration.

  QUESTION :

  Comment s'assurer de la validité du livre => par l'ISBN ? en faisant une
  recherche sur Amazon (sur un autre site)
  """
  use LdQWeb.FeatureCase, async: false

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  test "Un utilisateur quelconque peut soumettre un nouveau livre" do

    user = make_user_with_session(%{name: "Auteur DuLivre"})

    user
    |> rejoint_la_page("/")
    |> clique_le_lien("soumettre votre livre")
    # Il doit se connecter
    |> et_voit("h2", "Identification")
    
    |> et_voit("h2", "Soumission d'un livre")

  end


  @tag :skip
  test "On peut soumettre un livre par son ISBN" do
  end

  @tag :skip
  test "On ne peut pas soumettre deux fois le même livre" do
  end

  @tag :skip
  test "Soumission par quelqu'un d'autre que l'auteur" do

  end

end