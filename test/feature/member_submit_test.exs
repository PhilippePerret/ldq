defmodule LdQWeb.MemberSubmitFeatureTest do
  @moduledoc """
  Module testant l'inscription (candidature) au comité
  de lecture.

  TODO
    - isoler (fonction) la procédure pour candidater pour
      le comité et l'utiliser pour les possibilités
      de suivi :
        - candidature refusée
        - candidature directement acceptée
        - candidature soumise à test réussi (-> acceptation)
        - candidature soumise à test échoué (-> refus)

  """
  use LdQWeb.FeatureCase, async: false

  import TestHelpers
  import FeaturePublicMethods # Méthodes je_rejoins, etc.

  # use Wallaby.Feature # notamment pour new_session

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ

  def visiteur_candidate_pour_le_comite(session, params \\ %{}) do
    attrs = %{password: "Un mot de passe pour cette session"}
    user  = je = LdQ.ComptesFixtures.user_fixture(attrs)
    w("#{user.name} vient s'identifier", :blue)
    session
    |> je_rejoins_la_page("/users/log_in")
    |> pause(1)
    |> la_page_contient("input", %{type: "email", id: "user_email", name: "user[email]"})
    |> je_remplis_le_champ("Mail") |> avec(user.email)
    |> je_remplis_le_champ("Mot de passe") |> avec(attrs.password)
    |> pause(1)
    |> je_clique_le_bouton("Se connecter")

    point_test = NaiveDateTime.utc_now()

    session
    |> je_rejoins_la_page("/", "pour trouver un lien vers la candidature")
    |> je_clique_le_lien("devenir membre du comité de lecture")
    |> pause(1)
    |> la_page_contient("h2", "Candidature au comité de lecture")
    |> la_page_contient("h3", "Formulaire de soumission de la candidature")
    |> je_remplis_le_champ("Motivation") 
      |> avec("Pour participer à l'essor de ce label")
    |> je_remplis_le_champ("Genres de prédilection")
      |> avec("Fantaisie, Polar, Romance")
    |> je_mets_le_bon_captcha()
    |> pause(1)
    |> je_clique_le_bouton("Soumettre")
    # L'user doit rejoindre la page lui annonçant que sa candidature
    # a bien été prise en compte
    |> pause(1)
    |> la_page_contient("h2", "Candidature au comité de lecture")
    |> la_page_contient("#{je.name}, votre candidature a bien été enregistrée.")

    je |> recois_un_mail(after: point_test, subject: "Enregistrement de votre candidature", content: [~r/Ch(er|ère) #{user.name}/, "Nous vous confirmons que votre candidature", "L’Administration du Label"], strict: false)

    %{
      user: je,
      point_test: point_test
    }
  end

  def make_admin(params \\ %{}) do
    admin_attrs = %{
      email: "admin@lecture-de-qualite.fr",
      password: "motdepasseadministrateur", 
      privileges: 64
    }
    LdQ.ComptesFixtures.user_fixture(admin_attrs)
    |> Map.put(:password, admin_attrs.password)
    # |> IO.inspect(label: "\nAdmin")
  end

  feature "Acceptation directe de la candidature au comité de lecture", %{session: session} do
    
    detruire_les_mails()
    admin = make_admin()

    params = visiteur_candidate_pour_le_comite(session)
    user = params.user
    point_test = params.point_test

    # Une procédure a dû être enregistrée
    # Mais il est inutile de tester son enregistrement puisque
    # c'est fait indirectement par la suite.

    # L'administrateur clique sur son lien dans le mail et
    # rejoint la page de la procédure (on simule son identification
    # puisqu'il n'y a pas de sessions ici).
    {:ok, session_admin} = Wallaby.start_session()

    admin = Map.put(admin, :session, session_admin)
    admin 
    |> recoit_un_mail(after: point_test, subject: "Soumission d'une candidature", content: [~r/Ch(er|ère) administrat(eur|rice),/, "Name", "#{user.name}", ~s(<a href="mailto:#{user.email}">#{user.email}</a>), "acceptée, refusée ou soumise à un test"], strict: false)
    |> rejoint_le_lien_du_mail("Voir la procédure") # => session
    |> pause(1)
    |> la_page_contient("h2", "Candidature au comité de lecture")
    |> la_page_contient_le_bouton("Accepter")
    |> pause(1)
    |> je_clique_le_lien("Accepter")
    |> pause(10)

    # TODO (VOIR HAUT DE PAGE)
    
  end

  # feature "Refus direct de la candidature au comité de lecture", %{session: session} do
  #   # TODO
  # |> la_page_contient_le_bouton("Refuser")
  # |> la_page_contient("textarea", %{id: "motif_refus"})
  # end
  
  # feature "Candidature au comité acceptée après test", %{session: session} do
  #   # TODO
  # |> la_page_contient_le_bouton("Soumettre au test")
  # end

  # feature "Candidature au comité refusée après test", %{session: session} do
  #   # TODO
  # |> la_page_contient_le_bouton("Soumettre au test")
  # end

  # # --- Autres tests particularités ---
  # test "Un utilisateur ayant déjà soumis sa candidature ne peut plus le faire" do
  #   # TODO
  # end
  # test "Un membre du comité ne peut soumettre sa candidature" do
  #   # TODO
  # end

end