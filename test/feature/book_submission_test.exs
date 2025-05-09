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

    user = make_user_with_session(%{name: "Autrice DuLivre"})

    user
    |> rejoint_la_page("/")
    |> clique_le_lien("soumettre votre livre")
    # Il doit se connecter
    |> se_connecte()
    |> pause(1)
    |> et_voit("h2", "Soumission d’un livre")
    |> pause(1)
    # Il trouve un formulaire pour choisir entre définir le livre par son ISBN
    # ou par formulaire
    |> et_voit(["Soumettre par formulaire", "Soumettre par ISBN"])
    # |> remplit_le_champ("ISBN") |> avec("9798883337573") # Livre gabarits
    |> remplit_le_champ("ISBN") |> avec("9782487613027") # Analyse Au clair de Lune
    # https://openlibrary.org/isbn/9798883337573.json
    |> choisit_le_bon_captcha(%{form_id: "form-submit-with-isbn", prefix: "by_isbn"})
    |> pause(1)
    |> clique_le_bouton("Soumettre par ISBN")
    |> pause(1)
    # Ici, le programme recherche le livre par son isbn
    |> pause(1)
    |> et_voit("h2", "Caractéristiques du livre")
    |> pause(5)
    |> et_voit(["Titre du livre", "Autrice/auteur", "ISBN du livre"])
    |> pause(20)

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