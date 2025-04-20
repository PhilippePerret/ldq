defmodule LdQWeb.MemberSubmitFeatureTest do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers

  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ

  feature "un utilisateur accède au formulaire de candidature", %{session: session} do
    attrs = %{password: "Un mot de passe pour cette session"}
    user = LdQ.ComptesFixtures.user_fixture(attrs)

    w("#{user.name} vient s'identifier", :blue)
    session
    |> visit("/users/log_in")
    |> fill_in(WQ.text_field("Mail"), with: user.email)
    |> fill_in(WQ.text_field("Mot de passe"), with: attrs.password)
    |> click(WQ.button("Se connecter"))

    IO.puts "#{user.name} rejoint la page pour poser sa candidature"
    session
    |> visit("/form/member-submit")
    
    IO.puts "Il trouve le bon titre et le formulaire"
    assert WB.text(session, css("h2")) =~ "Formulaire de soumission de candidature"

  end
end