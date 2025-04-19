defmodule LdQWeb.MemberSubmitFeatureTest do
  use LdQWeb.FeatureCase, async: false

  feature "un utilisateur accède au formulaire de candidature", %{session: session} do
    user = LdQ.ComptesFixtures.user_fixture()
    session
    |> visit("/users/log_in")
    |> fill_in(Query.text_field("Email"), with: user.email)
    |> fill_in(Query.text_field("Mot de passe"), with: "valid_user_password")
    |> click(Query.button("Se connecter"))
    |> visit("/form/member-submit")
    |> assert_has(css("h2", text: "Formulaire de candidature"))
  end
end