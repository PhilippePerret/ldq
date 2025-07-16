defmodule LdQWeb.CandidatureMembreStep0101 do
  @moduledoc """
  Test pour voir si un user identifié (donc inscrit) peut proposer sa candidature au comité de lecture.

  Ce test doit initier une nouvelle procédure associtée à l'user.
  """
  use LdQWeb.FeatureCase, async: false
  import TestHelpers, except: [now: 0]
  import FeaturePublicMethods

  test "Un user inscrit et identifié peut proposer sa candidature au comité" do

  end

end