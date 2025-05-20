defmodule LdQWeb.BookSubmissionTestsStep2_2 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  @tag :author
  test "Après soumission, l'auteur du livre peut venir confirmer la soumission" do
    %{user: user, procedure: procedure} = bdd_load("book-just-submitted")
    # IO.inspect(test_data, label: "Données du test")
    # |> IO.inspect(label: "La procédure")

    file_book_path = Path.join(["test","assets","files", "book_pour_soumission.pdf"])

    author = get_author(procedure.data["author_id"])
    _author_as_user = start_session(author.user, [])
    user = get_user_with_session(user)
    # Map.put(author_as_user, :password, "passepartout")
    Map.put(user, :password, "passepartout")
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(1)
    |> et_voit("h3", "Confirmation de la soumission")
    |> remplit_le_champ("Sous-titre optionnel") |> avec("Mon sous-titre de livre")
    |> remplit_le_champ("Année de publication") |> avec("2024")
    # |> pause(60)
    |> coche_la_case("#book_accord_regles")
    |> depose_le_fichier(file_book_path, "#book_book_file")
    |> choisit_le_bon_captcha("book")
    |> pause(5)
    |> clique_le_bouton("Soumettre mon livre")
    # --- Vérification ---
    |> et_voit("h3", "Soumission confirmée")
    |> et_voit("Merci d'avoir confirmé la soumission de votre livre")
  end

end