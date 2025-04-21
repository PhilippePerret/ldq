defmodule LdQWeb.MemberSubmitFeatureTest do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers
  import FeaturesMethods # Méthodes je_rejoins, etc.

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ

  feature "un utilisateur accède au formulaire de candidature", %{session: session} do
    attrs = %{password: "Un mot de passe pour cette session"}
    user = LdQ.ComptesFixtures.user_fixture(attrs)

    w("#{user.name} vient s'identifier", :blue)
    session
    |> je_rejoins_la_page("/users/log_in")
    |> pause(1)
    |> je_remplis_le_champ("Mail") |> avec(user.email)
    |> je_remplis_le_champ("Mot de passe") |> avec(attrs.password)
    |> pause(2)
    |> je_clique_le_bouton("Se connecter")

    session
    |> je_rejoins_la_page("/form/member-submit", "pour poser ma candidature")
    |> pause(2)
    |> la_page_contient("h2", ~r/Formulaire de soumission de candidature/)
    |> je_remplis_le_champ("Motivation") 
      |> avec("Pour participer au label")
    |> je_coche_la_case("candidat_has_genre")
    |> je_remplis_le_champ("Genres de prédilections")
      |> avec("Fantaisie, Polar, Romance")
    |> pause(2)
    |> je_clique_le_bouton("Soumettre ma candidature")
    |> pause(2)
    |> la_page_contient("h2", "Candidature enregistrée")
    |> la_page_contient("p", "Votre candidature a été enregistrée.")

    # TODO Une procédure a dû être enregistrée
    
    # TODO Des mails ont dû être envoyés
  end

  test "Un utilisateur ayant déjà soumis sa candidature ne peut plus le faire" do
    # TODO
  end
  test "Un membre du comité ne peut soumettre sa candidature" do
    # TODO
  end

end