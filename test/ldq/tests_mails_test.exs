defmodule LdQ.TestsMailsTest do
  use ExUnit.Case

  alias LdQ.Tests.Mails

  import TestHelpers
  import FeaturePublicMethods

  setup do
     detruire_les_mails()
     :ok
  end

  def create_mail, do: create_mail(%{})
  def create_mail(props) when is_list(props) do
    props =
    Enum.reduce(props, %{}, fn {key, value}, map ->
      Map.put(map, key, value)
    end)
    create_mail(props)
  end
  def create_mail(props) do
    Map.merge(%{
      to: "destinataire@chez.lui",
      from: "expediteur@chez.lui",
      subject: "Le sujet par défaut", 
      body: "<p>Le corps du message par défaut.</p>",
      mail_id: nil,
      attachment: nil
    }, props) 
    |> Mails.create()
    # |> IO.inspect(label: "Mail créé")
  end

  def trouver_un_mail_avec(props) do
    assert Mails.find(props) |> Enum.count == 1
  end

  def trouver_aucun_mail_avec(props) do
    assert Enum.empty?(Mails.find(props))
  end

  def nombre_mails do
    Mails.get_all() |> Enum.count()
  end

  describe "méthode find" do
    test "je peux trouver un mail par le mail du destinataire" do
      create_mail()
      assert Enum.empty?(Mails.find(from: "destinataire@chez.lui"))
      trouver_un_mail_avec(to: "destinataire@chez.lui")
    end
    test "on peut trouver un mail par le mail de l'expéditeur" do
      create_mail()
      assert Enum.empty?(Mails.find(to: "expediteur@chez.lui"))
      trouver_un_mail_avec(from: "expediteur@chez.lui")
    end
    test "On peut trouver par l'identifiant du mail" do
      create_mail(mail_id: "mon_id_de_mail_test")
      trouver_un_mail_avec(mail_id: "mon_id_de_mail_test")
    end

    test "On peut trouver un mail par le sujet exact" do
      lesujet = "Un sujet unique du #{Date.utc_today()}"
      trouver_aucun_mail_avec(subject: lesujet)
      create_mail(subject: lesujet)
      trouver_un_mail_avec(subject: lesujet)
    end

    test "On peut trouver un mail par une partie du sujet" do
      lesujet = "Sujet vraiment unique du #{Date.utc_today()}"
      trouver_aucun_mail_avec(subject: "vraiment unique")
      create_mail(subject: lesujet)
      trouver_un_mail_avec(subject: "vraiment unique")
    end
    test "on peut trouver un mail avec plusieurs partie du sujet" do
      lesujet = "Sujet tout à fait unique du #{Date.utc_today()}"
      trouver_aucun_mail_avec(subject: ["unique", "tout à fait"])
      create_mail(subject: lesujet)
      trouver_un_mail_avec(subject: ["unique", "tout à fait"])
    end

    test "On peut trouver un mail avec une partie du body" do
      lebody = "<p>C'est le body complet</p>"
      trouver_aucun_mail_avec(body: lebody)
      create_mail(body: lebody)
      trouver_un_mail_avec(body: lebody)
    end

    test "On peut trouver un mail avec une partie seulement du body" do
      lebody = "<p>C'est le body complet et entier pour voir.</p>"
      trouver_aucun_mail_avec(body: "entier pour")
      create_mail(body: lebody)
      trouver_un_mail_avec(body: "entier pour")
    end

    test "On peut trouver un mail avec des parties du body" do
      lebody = "<p>C'est le body complet et entier pour voir.</p>"
      trouver_aucun_mail_avec(body: ["pour", "entier", "voir"])
      create_mail(body: lebody)
      trouver_un_mail_avec(body: ["pour", "entier", "voir"])
    end

    test "On peut trouver un mail avec tous les critères donnés" do
      # On créer autant de mails que voulus avec doublons de chaque
      # propriété mais un seul qui les possèdes toutes
      bon_expediteur = "bonexpe@chez.lui"
      bon_destinataire = "bondestin@chez.lui"
      bon_sujet = "Le très bon sujet"
      bon_mail_id = "un-bon-mail-id"
      bon_body = "<p>Le bon Body pour voir</p>"

      trouver_aucun_mail_avec(to: bon_destinataire, from: bon_expediteur, subject: bon_sujet, mail_id: bon_mail_id, body: bon_body)
      # Création des mails (au moins deux de chaque)
      create_mail(to: bon_destinataire)
      create_mail(from: bon_expediteur)
      create_mail(subject: bon_sujet)
      create_mail(body: bon_body)
      create_mail(mail_id: bon_mail_id)
      # Le bon qui contient tout
      create_mail(to: bon_destinataire, from: bon_expediteur, subject: bon_sujet, mail_id: bon_mail_id, body: bon_body)
      # --- Vérification ---
      assert nombre_mails() == 6, "Il devrait y avoir 6 mails, il y en a #{nombre_mails()}"
      trouver_un_mail_avec(to: bon_destinataire, from: bon_expediteur, subject: bon_sujet, mail_id: bon_mail_id, body: bon_body)

    end


  end #/describe méthode find/1

end