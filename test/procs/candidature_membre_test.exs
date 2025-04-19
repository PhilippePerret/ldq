defmodule LdQWeb.ProcCandidatureMembreComite do
  use LdQWeb.ConnCase, async: true
  import Swoosh.TestAssertions

  alias LdQWeb.ConnCase

  # Pour les mails
  # assert_mail_sent subject: "<le sujet>", to: {"nom", "mail"}, html_body: ~r/.../


  setup do
    Swoosh.TestAssertions.assert_no_email_sent()
    :ok
  end

  setup %{conn: conn} do
    ConnCase.register_and_log_in_user(%{conn: conn})
  end

  describe "Procédures de candidature" do

    # @tag :skip
    test "avec un candidat non valide",  %{conn: conn, user: author} do
      conn = get(conn, "/form/member-submit")
      assert html_response(conn, 200) =~ "<h2>Formulaire de soumission de candidature"
    end

    @tag :skip
    test "avec un candidat qui manque le test",  %{conn: conn, user: author} do
    end

    @tag :skip
    test "avec un candidat qui réussit le test",  %{conn: conn, user: author} do
    end

    @tag :skip
    test "avec un candidat qui n'a pas besoin de passer le test",  %{conn: conn, user: author} do
    end

  end #/describe les procédures de candidature
  
end