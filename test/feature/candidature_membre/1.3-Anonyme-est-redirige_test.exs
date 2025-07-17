defmodule LdQWeb.CandidatureMembreStep0103 do
  @moduledoc """
  Test s'assurant qu'un visiteur non identifié doit aller s'identifier.

  """
  use LdQWeb.FeatureCase, async: false
  import TestHelpers, except: [now: 0]
  import FeaturePublicMethods

  test "Un user non identifié doit aller s'identifier" do
    # 
    # = PHOTOGRAPHIE =
    # 
    # Ce test ne produit aucune photographie.
    # 
    user = make_user_with_session()

    user
    |> rejoint_la_page("/")
    |> clique_le_lien("rejoindre le comité")
    # |> pause(2)
    |> et_voit("vous devez vous identifier ou vous inscrire")
    |> pause(2)
  end

end