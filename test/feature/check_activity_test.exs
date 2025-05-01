defmodule LdQWeb.CheckActivityTest do
  @moduledoc """
  Test systématique pour vérifier que les tests des activités
  sont valides
  Ce sont donc des tests de tests  
  """
  # use LdQWeb.FeatureCase, async: false
  use LdQ.DataCase, async: false

  # import TestHelpers
  import FeaturePublicMethods # Méthodes rejoint_la_page, etc.
  # alias LdQ.Comptes.User
  import LdQ.ComptesFixtures

  alias LdQ.Site.Log

  alias Random.RandMethods, as: Rand

  # Les méthodes testées
  # import Feature.LogTestMethods, except: [check_activities: 1]


  def now do
    NaiveDateTime.utc_now()
  end
  def ilya(nombre, unit) do
    NaiveDateTime.add(now(), - nombre, unit)
  end

  def create_log(attrs \\ []) do
    text        = Keyword.get(attrs, :text, Rand.random_text(30))
    otype       = Keyword.get(attrs, :owner_type, "user")
    oid         = Keyword.get(attrs, :owner_id, make_simple_user().id)
    creator     = Keyword.get(attrs, :creator, make_simple_user())
    public      = Keyword.get(attrs, :public, true)
    inserted_at = Keyword.get(attrs, :inserted_at, now())
    Log.create(%{public: public, text: text, owner_type: otype, owner_id: oid, creator: creator, inserted_at: inserted_at})
  end

  def affiche_all_activities do
    IO.inspect(LdQ.Repo.all(LdQ.Site.Log), label: "\nToutes les activités")
  end

  describe "Méthode check_activities" do

    test "retourne nil aucune activité et on en cherche aucune" do
      res = check_activities(count: 0)
      assert(is_nil(res))
    end

    test "retourne un message d'erreur si on ne trouve pas le nombre d'activités voulues" do
      create_log()
      res = check_activities(count: 2)
      refute(is_nil(res))
      assert( res == "Bad activity count: expected: 2, actual: 1\n")
    end
    
    test "returne nil si on trouve le bon nombre d'activité" do
      create_log()
      create_log()
      res = check_activities(count: 2)
      assert(is_nil(res), res || "Pas d'erreur")
    end


    test "peut filtrer par date (after)" do
      create_log(inserted_at: ilya(2, :hour))
      create_log(inserted_at: ilya(3, :hour))
      create_log(inserted_at: ilya(30, :minute))
      create_log(inserted_at: ilya(20, :minute))
      create_log(inserted_at: ilya(10, :minute))
      res = check_activities(after: ilya(40, :minute), count: 3)
      assert( is_nil(res), res || "pas d'erreur")
    end

  end
  
end