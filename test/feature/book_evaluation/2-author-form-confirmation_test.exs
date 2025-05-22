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
    book_file_dest = Path.join(["priv", "static", "uploads", "books", "book-#{procedure.id}.pdf"])


    author = get_author(procedure.data["author_id"])
    _author_as_user = start_session(author.user, [])
    user = get_user_with_session(user)
    # Map.put(author_as_user, :password, "passepartout")
    Map.put(user, :password, "passepartout")
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(1)
    |> et_voit("h3", "Confirmation de la soumission")
    # |> pause(100)
    |> remplit_le_champ("Sous-titre optionnel") |> avec("Mon sous-titre de livre")
    |> remplit_le_champ("URL de commande") |> avec("https://www.amazon.fr/dp/B09521VMZQ")
    |> remplit_le_champ("Année de publication") |> avec("2024")
    # |> coche_la_case("#book_accord_regles")
    # Je fais exprès d'oublier de cocher la case des règles
    |> et_voit("input[type=file]", %{id: "book_file"})
    |> depose_le_fichier(file_book_path, "#book_file")
    |> choisit_le_bon_captcha("book")
    |> clique_le_bouton("Soumettre mon livre")
    # --- Vérification ---
    |> pause(1)
    # On doit corriger les erreurs
    |> et_voit("h3", "Confirmation de la soumission")
    |> et_ne_voit_pas("h3", "Soumission confirmée")
    |> et_voit(~s(div.form-error[data-field="accord_regles"]), "Il faut approuver les règles")
    |> et_ne_voit_pas("input", %{id: "book_file"})
    |> et_voit("Transmis avec succès")
    |> et_voit("div.error", "Merci de bien vouloir corriger")
    |> pause(1)
    # --- Correction du formulaire ---
    # (note : les autres valeurs doivent avoir été remises)
    |> coche_la_case("#accord_regles")
    |> choisit_le_bon_captcha("book")
    |> clique_le_bouton("Soumettre mon livre")
    |> pause(5)
    # --- Vérification ---
    |> pause(1)
    |> et_voit("h3", "Soumission confirmée")
    |> et_voit("Merci d'avoir confirmé la soumission de votre livre")

    # Le fichier doit avoir été transmis
    assert File.exists?(book_file_dest)
  end

  @tag :skip
  test "le même sans transmettre une URL de commande valide" do
    # On propose de retourner au formulaire
  end
  
  @tag :skip
  test "le même sans transmettre le fichier et sans cocher la case “je le transmettrai par mail”" do
    # On propose de retourner au formulaire
  end
  
  @tag :skip
  test "le même sans transmettre le fichier et en cochant la case “je le transmettrai par mail”" do
  end
  
  @tag :skip
  test "le même sans cocher la case d'acceptation des règles" do
    # On doit renvoyer au formulaire et demander de la cocher
  end

  @tag :skip
  test "le même en indiquant une pré-version qui n'existe pas" do
    # On doit proposer de renvoyer au formulaire pour la corriger
  end


end