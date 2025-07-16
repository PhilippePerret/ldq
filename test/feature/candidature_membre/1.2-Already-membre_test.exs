defmodule LdQWeb.CandidatureMembreStep0102 do
  @moduledoc """
  Test s'assurant qu'un user déjà membre du comité ne peut pas candidater à nouveau.

  """
  use LdQWeb.FeatureCase, async: false
  import TestHelpers, except: [now: 0]
  import FeaturePublicMethods

  test "Un user déjà membre ne peut pas reproposer sa candidature au comité" do

  end

end