defmodule LdQWeb.BookSubmissionTestsStep2_2 do
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  @tag :author
  test "Après soumission, l'auteur du livre peut venir confirmer la soumission" do
    # 
    # -PHOTOGRAPHIE-
    # Ce test crée la photographie "evaluation-book/2-autorisation-auteur" qui
    # permettra de poursuivre le test de l'évaluation.
    # 
    
    
    %{user: user, procedure: procedure} = bddshot("evaluation-book/1-book-just-submitted")
    # IO.inspect(test_data, label: "Données du test")
    # |> IO.inspect(label: "La procédure")

    
    file_book_path = Path.join(["test","assets","files", "book_pour_soumission.pdf"])
    book_file_dest = Path.join(["priv", "static", "uploads", "books", "book-#{procedure.id}.pdf"])
    
    book_subtitle     = "Mon sous-titre de livre"
    book_pitch        = "Ceci est le résumé court du livre qui raconte l'histoire en bref."
    book_url_command  = "https://www.amazon.fr/dp/B09521VMZQ"
    
    point_test = now()

    author = get_author(procedure.data["author_id"])
    _author_as_user = start_session(author.user, [])
    user = get_user_with_session(user)
    # Map.put(author_as_user, :password, "passepartout")
    Map.put(user, :password, "passepartout")
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> pause(1)
    |> et_voit("h3", "Confirmation de la soumission")
    # |> pause(100)
    |> remplit_le_champ("Sous-titre optionnel") |> avec(book_subtitle)
    |> remplit_le_champ("URL de commande") |> avec(book_url_command)
    |> remplit_le_champ("Date de publication") |> avec(~D[2024-09-12])
    |> remplit_le_champ("Pitch (résumé court)") |> avec(book_pitch)
    # Je fais exprès d'oublier de cocher la case des règles
    # |> coche_la_case("#book_accord_regles")
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
    # --- Vérification ---
    |> pause(1)
    |> et_voit("h3", "Soumission confirmée")
    |> et_voit(["Merci", "d’avoir confirmé la soumission de votre livre"])
    |> pause(1)

    # --- Vérifications ---
    
    admin = make_admin()

    # Le fichier doit avoir été transmis
    assert( File.exists?(book_file_dest), "Le manuscrit/livre de l'auteur est introuvable… (#{inspect book_file_dest})")
  
    # Les nouvelles données du livre ont été enregistrées
    book_data = LdQ.Library.Book.get(procedure.data["book_id"], :all)
    assert(book_data.subtitle == book_subtitle)
    assert(book_data.url_command == book_url_command)
    assert(book_data.pitch == book_pitch)
    # data Soumission
    assert(NaiveDateTime.after?(book_data.submitted_at, point_test))
    
    # La procédure contient toujours les bonnes données
    fresh_proc = LdQ.Procedure.get(procedure.id)
    # IO.inspect(fresh_proc, label: "\nDONNÉES PROCÉDURE RAFRAICHIE")
    refute(is_nil(fresh_proc.data))
    refute(is_nil(fresh_proc.data["book_id"]))
    refute(is_nil(fresh_proc.data["author_id"]))
    
    # Mail envoyé aux administrateurs
    admin |> recoit_un_mail(after: point_test, mail_id: "to_admin-author-autorise-evaluation")
    # Mail envoyé à l'auteur pour confirmer
    author |> recoit_un_mail(after: point_test, mail_id: "to_author-confirme-son-autorisation")
    # Annonce activité
    assert_activity(after: point_test, public: true, content: "Mise en évaluation du livre <em>#{book_data.title}</em>")
  
    # On crée une photographie
    bddshot("evaluation-book/2-autorisation-auteur", %{
      author: author,
      point_test: point_test,
      procedure_id: procedure.id
    })
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