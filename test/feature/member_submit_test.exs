defmodule LdQWeb.MemberSubmitFeatureTest do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers
  import FeaturePublicMethods # Méthodes je_rejoins, etc.

  # use Wallaby.Feature # notamment pour new_session

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ

  feature "un utilisateur accède au formulaire de candidature", %{session: session} do

    admin_attrs = %{
      email: "admin@lecture-de-qualite.fr",
      password: "motdepasseadministrateur", 
      privileges: 64
    }
    admin = LdQ.ComptesFixtures.user_fixture(admin_attrs)
    |> Map.put(:password, admin_attrs.password)
    |> IO.inspect(label: "\nAdmin")

    attrs = %{password: "Un mot de passe pour cette session"}
    user  = je = LdQ.ComptesFixtures.user_fixture(attrs)

    detruire_les_mails()

    w("#{user.name} vient s'identifier", :blue)
    session
    |> je_rejoins_la_page("/users/log_in")
    |> pause(1)
    |> je_remplis_le_champ("Mail") |> avec(user.email)
    |> je_remplis_le_champ("Mot de passe") |> avec(attrs.password)
    |> pause(1)
    |> je_clique_le_bouton("Se connecter")

    point_test = NaiveDateTime.utc_now()

    session
    |> je_rejoins_la_page("/form/member-submit", "pour poser ma candidature")
    |> pause(1)
    |> la_page_contient("h2", ~r/Formulaire de soumission de candidature/)
    |> je_remplis_le_champ("Motivation") 
      |> avec("Pour participer au label")
    |> je_coche_la_case("candidat_has_genre")
    |> je_remplis_le_champ("Genres de prédilections")
      |> avec("Fantaisie, Polar, Romance")
    |> pause(1)
    |> je_clique_le_bouton("Soumettre ma candidature")
    |> pause(1)
    |> la_page_contient("h2", "Candidature enregistrée")
    |> la_page_contient("p", "Votre candidature a été enregistrée.")

    je |> recois_un_mail(after: point_test, subject: "Enregistrement de votre candidature", content: [~r/Ch(er|ère) #{user.name}/, "Nous vous confirmons que votre candidature", "L’Administration du Label"], strict: false)
    
    # Une procédure a dû être enregistrée
    # TODO

    # L'administrateur clique sur son lien dans le mail et
    # rejoint la page de la procédure (on simule son identification
    # puisqu'il n'y a pas de sessions ici).
    {:ok, session_admin} = Wallaby.start_session()

    admin = Map.put(admin, :session, session_admin)
    admin 
    |> recoit_un_mail(after: point_test, subject: "Soumission d'une candidature", content: [~r/Ch(er|ère) administrat(eur|rice),/, "Name", "#{user.name}", ~s(<a href="mailto:#{user.email}">#{user.email}</a>), "acceptée, refusée ou soumise à un test"], strict: false)
    |> rejoint_le_lien_du_mail("Voir la procédure")
    |> la_page_contient("h2", "Procédure")

    # L'administrateur peut rejoindre le lien du mail
    
  end

  test "Un utilisateur ayant déjà soumis sa candidature ne peut plus le faire" do
    # TODO
  end
  test "Un membre du comité ne peut soumettre sa candidature" do
    # TODO
  end

end