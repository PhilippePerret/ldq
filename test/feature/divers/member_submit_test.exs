defmodule LdQWeb.MemberSubmitFeatureTest do
  @moduledoc """
  Module testant l'inscription (candidature) au comité
  de lecture.

  TODO

  """
  use LdQWeb.FeatureCase, async: false

  import TestHelpers #, only: [w: 2, pause: 2, create_procedure: 1, refresh_user: 1]
  import FeaturePublicMethods, except: [now: 0] # Méthodes rejoint_la_page, etc.

  # alias LdQ.Comptes.User
  # alias Wallaby.Browser,  as: WB
  # alias Wallaby.Query,    as: WQ

  def visiteur_candidate_pour_le_comite(attrs \\ %{}) do
    attrs = if is_nil(Map.get(attrs, :sexe)) do
      Map.put(attrs, :sexe, "F")
    else attrs end
    user  = make_user_with_session(attrs)
    je = user
    w("#{user.name} vient s'identifier", :blue)

    user = 
      user
      # |> IO.inspect(label: "User courant")
      |> se_connecte()

    point_test = NaiveDateTime.utc_now()

    user
    |> pause(1)
    |> rejoint_la_page("/", "pour trouver un lien vers la candidature")
    |> move_window(left: 700)
    |> clique_le_lien("devenir membre du comité de lecture")
    |> pause(1)
    |> et_voit("h2", "Candidature au comité de lecture")
    |> et_voit("h3", "Formulaire de soumission de la candidature")
    |> remplit_le_champ("Motivation") 
      |> avec("Pour participer à l'essor de ce label")
    |> remplit_le_champ("Genres de prédilection")
      |> avec("Fantaisie, Polar, Romance")
    |> pause(1)
    |> choisit_le_bon_captcha(%{prefix: "f"})
    |> clique_le_bouton("Soumettre")
    # L'user doit rejoindre la page lui annonçant que sa candidature
    # a bien été prise en compte
    |> pause(1)
    |> et_voit("h2", "Candidature au comité de lecture")
    |> et_voit("#{je.name}, votre candidature a bien été enregistrée.")

    user 
    |> recoit_un_mail(after: point_test, subject: "Enregistrement de votre candidature", content: [~r/Ch(er|ère) #{user.name}/, "Nous vous confirmons que votre candidature", "L’Administration du Label"], strict: false)

    {user, point_test}
  end

  def user_rejoint_le_test(user) do
    procedure = create_procedure(owner: user, dim: "candidature-comite", step: "test_admission_comite")
    user = Map.put(user, :procedure, procedure)

    user
    |> se_connecte()
    |> pause(1)
    |> rejoint_la_page("proc/#{procedure.id}")
    |> et_voit("h3", "Test d'admission au comité de lecture")
    |> et_voit("form", %{id: "test-candidature"})
    |> pause(1)

    # On relève les données des questions pour ce test
    path = Path.join(["test","xtmp","test-comite-#{user.id}"])
    data_questions = :erlang.binary_to_term(File.read!(path))
    # IO.inspect(data_questions, label: "Données des questions")
    # On détruit toujours le fichier
    File.rm(path)

    {user, data_questions}
  end


  # @return procedure La procédure
  defp candidat_choisit_reponses(user, nombre_bonnes, nombre_mauvaises) do
    {user, data_questions} = user_rejoint_le_test(user)

    # L'user choisit toutes les mauvaises réponses
    data_questions
    |> Enum.shuffle()
    |> Enum.reduce(%{bons: 0, bads: 0}, fn dquest, reps ->
      {id_choix, bons, bads} =
        cond do
        reps.bons < nombre_bonnes ->
          {"Q#{dquest.id}_rep-#{dquest.right}", reps.bons + 1, reps.bads}
        is_nil(nombre_mauvaises) ->
          {"Q#{dquest.id}_rep-100", reps.bons + 1, reps.bads}
        reps.bads < nombre_mauvaises ->
          choix = if dquest.right == 0, do: 1, else: 0
          {"Q#{dquest.id}_rep-#{choix}", reps.bons, reps.bads + 1}
        true -> 
          {"Q#{dquest.id}_rep-100", reps.bons, reps.bads}
        end
      user
      |> coche_le_choix(id_choix)
      |> pause(0.3)
      %{bons: bons, bads: bads}
    end)

    user
  end

  # @tag :skip
  test "Un candidat qui met toutes les bonnes réponses est reçu" do
    user = make_user_with_session()
    {user, data_questions} = user_rejoint_le_test(user)
    data_questions
    |> Enum.each(fn dquest ->
      id_choix = "Q#{dquest.id}_rep-#{dquest.right}"
      user
      |> coche_le_choix(id_choix)
      |> pause(0.3)
    end)

    user = Map.put(user, :last_point_test, now())
    # Après avoir rempli le questionnaire, l'user peut le soumettre
    user
    |> pause(1)
    |> clique_le_bouton("Soumettre le test")
    |> pause(1)
    |> et_voit("Votre total est de 15 / 15")
    |> et_voit("Vous avez passé ce test avec succès")

    check_test_success(user)
  end

  # @tag :skip
  test "Un candidat qui met assez de bonnes réponses est reçu" do
    user = make_user_with_session()
    user = candidat_choisit_reponses(user, 11, 0)

    user = Map.put(user, :last_point_test, now())

    # Après avoir rempli le questionnaire, l'user peut le soumettre
    user
    |> pause(1)
    |> clique_le_bouton("Soumettre le test")
    |> pause(1)
    |> et_voit("Votre total est de 11 / 15")
    |> et_voit("Vous avez passé ce test avec succès")

    check_test_success(user)
  end


  # @tag :skip
  test "Un candidat qui met assez de bonnes réponses mais trop de mauvaises échoue" do
    user = make_user_with_session()
    user = candidat_choisit_reponses(user, 11, 5)

    user = Map.put(user, :last_point_test, now())

    # Après avoir rempli le questionnaire, l'user peut le soumettre
    user
    |> pause(1)
    |> clique_le_bouton("Soumettre le test")
    |> pause(1)
    |> et_voit("Votre total est de 7 / 15")
    |> et_voit("vous n'avez pas le niveau requis")

    check_test_failure(user)
  end

  # @tag :skip
  test "Un candidat qui met toutes les mauvaises réponses échoue" do
    user = make_user_with_session()
    user = candidat_choisit_reponses(user, 0, 15)

    user = Map.put(user, :last_point_test, now())

    # Après avoir rempli le questionnaire, l'user peut le soumettre
    user
    |> pause(1)
    |> clique_le_bouton("Soumettre le test")
    |> pause(1)
    |> et_voit("Votre total est de -15 / 15")
    |> et_voit("vous n'avez pas le niveau requis")

    check_test_failure(user)
  end
  
  # @tag :skip
  test "Un candidat qui n'a pas assez de bonnes réponses échoue" do
    user = make_user_with_session()
    user = candidat_choisit_reponses(user, 9, 0)

    user = Map.put(user, :last_point_test, now())

    # Après avoir rempli le questionnaire, l'user peut le soumettre
    user
    |> pause(1)
    |> clique_le_bouton("Soumettre le test")
    |> pause(1)
    |> et_voit("Votre total est de 9 / 15")
    |> et_voit("vous n'avez pas le niveau requis")

    check_test_failure(user)
  end

  # @tag :skip
  test "Un candidat qui ne sait rien échoue" do
    user = make_user_with_session()
    # L'user choisit toutes les mauvaises réponses
    user = candidat_choisit_reponses(user, 0, nil)

    user = Map.put(user, :last_point_test, now())

    # Après avoir rempli le questionnaire, l'user peut le soumettre
    user
    |> pause(1)
    |> clique_le_bouton("Soumettre le test")
    |> pause(1)
    |> et_voit("Votre total est de 0 / 15")
    |> et_voit("vous n'avez pas le niveau requis")

    check_test_failure(user)
  end

  # @tag :skip
  test "Un candidat qui a réussi le test ne peut pas le repasser" do
    user = make_user_with_session()
    # L'user choisit toutes les mauvaises réponses
    user = candidat_choisit_reponses(user, 10, 0)
    # Après avoir rempli le questionnaire, l'user peut le soumettre
    user
    |> clique_le_bouton("Soumettre le test")
    |> pause(1)
    |> et_voit("Votre total est de 10 / 15")
    |> pause(1)

    user
    |> rejoint_la_page("/proc/#{user.procedure.id}")
    |> pause(1)
    |> et_ne_voit_pas("h3", "Test d'admission au comité de lecture")
    |> et_ne_voit_pas("form#test-candidature", ~r/./)
    |> et_voit("Désolé mais cette procédure n'existe pas ou plus.")
  
  end

  # @tag :skip
  test "Un candidat qui a échoué ne peut pas repasser le test" do
    user = make_user_with_session()
    # L'user choisit toutes les mauvaises réponses
    user = candidat_choisit_reponses(user, 9, 6)
    # Après avoir rempli le questionnaire, l'user peut le soumettre
    user
    |> clique_le_bouton("Soumettre le test")
    |> pause(1)
    |> et_voit("Votre total est de 3 / 15")
    |> et_voit("vous n'avez pas le niveau requis")

    user
    |> rejoint_la_page("/proc/#{user.procedure.id}")
    |> pause(1)
    |> et_ne_voit_pas("h3", "Test d'admission au comité de lecture")
    |> et_ne_voit_pas("form", %{id: "test-candidature"})
    |> et_voit("cette procédure n'existe pas ou plus.")
  end

  @tag :skip
  test "Un candidat qui réussit reçoit un montant de crédit proportionnel à son score" do
    # TODO Quand on connaitra mieux le fonctionnement du crédit
  end



  @tag :skip
  feature "Acceptation directe de la candidature au comité de lecture" do
    
    detruire_les_mails()

    {user, point_test} = visiteur_candidate_pour_le_comite()

    # Une procédure a dû être enregistrée
    # Mais il est inutile de tester son enregistrement puisque
    # c'est fait indirectement par la suite.

    # L'administrateur clique sur son lien dans le mail et
    # rejoint la page de la procédure (on simule son identification
    # puisqu'il n'y a pas de sessions ici).

    admin   = make_admin_with_session()
    member  = make_membre()

    admin
    |> recoit_un_mail(after: point_test, subject: "Soumission d'une candidature", content: [~r/Ch(er|ère) administrat(eur|rice),/, "Name", "#{user.name}", ~s(<a href="mailto:#{user.email}">#{user.email}</a>), "acceptée, refusée ou soumise à un test"], strict: false)
    |> rejoint_le_lien_du_mail("Voir la procédure") # => session
    |> pause(1)
    |> et_voit("h2", "Candidature au comité de lecture")
    |> la_page_contient_le_bouton("Accepter")
    |> pause(1)

    point_test = NaiveDateTime.utc_now()

    admin
    |> pause(2)
    |> clique_le_lien("Accepter")

    # --- Vérification ---
    # Le candidat change de statut (privilège)
    user = LdQ.Comptes.Getters.get_user!(user.id) # version rafraichie
    # |> IO.inspect(label: "\nUser rafraichi")
    is_reader = user.privileges |> Flag.has?(2)
    is_member = user.privileges |> Flag.has?(8)
    assert( is_reader and is_member, "Le candidat devrait être marqué comme lecteur (#{inspect is_reader}) et comme membre du comité (#{inspect is_member})")
    # Les administrateurs reçoivent un mail d'annonce
    admin
    |> recoit_un_mail(after: point_test, subject: "Nouveau membre au comité de lecture", content: ["une nouvelle membre", user.name, user.email], strict: false)
    # Les membres du comité de lecture reçoivent un mail
    member
    |> recoit_un_mail(after: point_test, subject: "Nouveau membre au comité de lecture", content: [user.name, user.email], strict: false)
    # Un log a été enregistré
    res = check_activities(after: point_test, owner: user, content: "#{user.name} vient de rejoindre le comité de lecture du label.")
    assert(is_nil(res), res || "pas d'erreur")
    # La page d'accueil affiche la nouvelle activité
    autreuser = make_simple_user()
    {:ok, sessionother} = Wallaby.start_session()
    autreuser = Map.put(autreuser, :session, sessionother)
    autreuser
    |> rejoint_la_page("/home")
    |> pause(2)
    |> et_voit("#{user.name} vient de rejoindre le comité de lecture du label.")

  end

  @tag :skip
  feature "Refus direct de la candidature au comité de lecture" do
    detruire_les_mails()

    {user, point_test} = visiteur_candidate_pour_le_comite()

    # procedure = 
    #   get_procedure(owner: user, submitter: user, dim: "candidature-comite")
    #   |> Enum.at(0)
    #   |> IO.inspect(label: "La procédure")

    admin   = make_admin_with_session()

    admin
    |> recoit_un_mail(after: point_test, subject: "Soumission d'une candidature", content: [~r/Ch(er|ère) administrat(eur|rice),/, "Name", "#{user.name}", ~s(<a href="mailto:#{user.email}">#{user.email}</a>), "acceptée, refusée ou soumise à un test"], strict: false)
    |> rejoint_le_lien_du_mail("Voir la procédure") # => session
    |> pause(1)
    |> et_voit("h2", "Candidature au comité de lecture")
    |> la_page_contient_le_bouton("Refuser")
    
    point_test = now()
    
    motif_refus = "C'est le motif motivé du refus."
    
    admin
    |> clique_le_lien("Refuser")
    |> pause(1)
    |> et_voit("h3", "Refus de candidature au comité de lecture")
    |> et_voit("form", %{id: "refus-form"})
    |> et_voit("textarea", %{id: "f_motif_refus"})
    |> remplit_le_champ("Motif du refus") |> avec(motif_refus)
    |> clique_le_bouton("Soumettre")
    |> pause(2)
    |> et_voit("p", "Le refus de la candidature de #{user.name} a été prise en compte.")

    # Mail envoyé à l'utilisateur lui annonçant la mauvaise nouvelle
    user
    |> recoit_un_mail(after: point_test, subject: "Votre candidature a été refusée")
    # Une activité (non publique) a été enregistrée
    res = check_activities(count: 1, after: point_test, owner: user, public: false, content: "Refus de la candidature de #{user.name} au motif de : #{motif_refus}")
    assert(is_nil(res), res || "pas d'erreur")
    # La procédure a été détruite
    procedures = get_procedure(owner: user, submitter: user, dim: "candidature-comite")
    assert(Enum.empty?(procedures), "La procédure devrait avoir été détruite.")

  end
  
  @tag :skip
  test "Candidature au comité acceptée après test" do
    detruire_les_mails()

    {user, point_test} = visiteur_candidate_pour_le_comite()

    admin   = make_admin_with_session()


    admin
    |> recoit_un_mail(after: point_test, subject: "Soumission d'une candidature", content: [~r/Ch(er|ère) administrat(eur|rice),/, "Name", "#{user.name}", ~s(<a href="mailto:#{user.email}">#{user.email}</a>), "acceptée, refusée ou soumise à un test"], strict: false)
    |> rejoint_le_lien_du_mail("Voir la procédure")

    point_test = now()

    admin
    |> pause(1)
    |> et_voit("h2", "Candidature au comité de lecture")
    |> la_page_contient_le_bouton("Soumettre à test")
    |> clique_le_lien("Soumettre à test")
    |> pause(1)
    # |> end_session()
    
    user
    |> focus()
    |> recoit_un_mail(after: point_test, subject: "Candidature comité de lecture - Demande de test")
    |> rejoint_le_lien_du_mail("Passer le test")
    |> pause(1)
    |> et_voit("Test d'admission")
    |> pause(1000)
  end

  # feature "Candidature au comité refusée après test", %{session: session} do
  #   # TODO
  # |> la_page_contient_le_bouton("Soumettre au test")
  # end

  # --- Autres tests particularités ---

  @tag :skip
  test "Un candidat ayant amorcé le test ne peut pas le recommencer à zéro" do

  end
  
  # test "Un utilisateur ayant déjà soumis sa candidature ne peut plus le faire" do
  #   # TODO
  # end

  # test "Un membre du comité ne peut soumettre sa candidature" do
  #   # TODO
  # end

  # Test commun de la réussite du test
  defp check_test_success(user) do
    # IO.inspect(user, label: "User dans check_test_success")
    # Il faut rafraichir l'user
    user = refresh_user(user)
    # IO.inspect(user, label: "User rafraichi")

    user
    |> recoit_un_mail(after: user.last_point_test, mail_id: "user-admission-comite")
    |> has_no_procedure(user.procedure)
    |> has_privileges(8)
    |> has_activity(after: user.last_point_test, content: "#{user.name} vient de rejoindre le comité")
    |> et_voit("Bravo")
  end

  defp check_test_failure(user) do
    # Il faut recharger l'user
    user = refresh_user(user)

    user
    |> has_not_privileges(8)
    |> has_no_procedure(user.procedure)
    |> et_voit("Désolé")
  end
end