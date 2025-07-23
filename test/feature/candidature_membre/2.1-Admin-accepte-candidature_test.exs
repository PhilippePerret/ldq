
defmodule LdQWeb.CandidatureMembreStep0201 do
  @moduledoc """
  Test de la validation de la candidature d'un membre du comité par un administrateur.

  """

    use LdQWeb.FeatureCase, async: false
    import TestHelpers, except: [now: 0]
    import FeaturePublicMethods


    test "Un administrateur peut valider aussitôt la candidature" do
      #
      # = PHOTOGRAPHIE =
      # Ce test produit la photographie 'candidature-comite/validation-directe'
  
      admin = make_admin_with_session()
    
      
      
    end
end
