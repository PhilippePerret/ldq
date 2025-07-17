defmodule LdQWeb.CandidatureMembreStep0101 do
  @moduledoc """
  Test pour voir si un user identifié (donc inscrit) peut proposer sa candidature au comité de lecture.

  Ce test doit initier une nouvelle procédure associtée à l'user.
  """
  use LdQWeb.FeatureCase, async: false
  import TestHelpers, except: [now: 0]
  import FeaturePublicMethods

  import Feature.FormTestMethods

  test "Un user inscrit et identifié peut proposer sa candidature au comité" do
    # 
    # = PHOTOGRAPHIE =
    # 
    # Ce test produit la photographie '1.1-Depot-candidature-comite'
    # 
    # Elle contient donc un user lambda enregistré avec une requête
    # (procédure) de demande de candidature au comité de lecture.
    # ('candidature-comite')
    # 
    user = make_user_with_session()

    user
    |> se_connecte()
    |> rejoint_la_page("/")
    |> clique_le_lien("rejoindre le comité")
    # |> pause(5)
    |> et_voit("merci de confirmer que vous voulez accomplir la procédure")
    # Il joue le bouton "Soumettre" sans cocher
    |> clique_le_bouton("Soumettre")
    |> pause(5)
    |> et_voit("Merci d’appouver les CGU afin de passer à la suite.")
    |> et_voit("Merci de répondre au captcha pour prouver que vous êtes humain.")
    |> pause(1)
    |> mettre_bon_captcha("f")
    |> pause(2)
    |> cocher_la_case("f_cgu")
    |> pause(2)
    |> clique_le_bouton("Soumettre")
    |> pause(5)
    |> et_voit("h2", "Candidature au comité de lecture")
    |> et_voit("h3", "Formulaire de candidature")

    bddshot("1.1-Depot-candidature-comite", %{
      user: user
    })
  end

end