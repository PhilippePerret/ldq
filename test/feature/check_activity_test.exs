defmodule LdQWeb.CheckActivityTest do
  @moduledoc """
  Test systématique pour vérifier que les tests des activités
  sont valides
  Ce sont donc des tests de tests, pas des tests de l'application.
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

  def create_log(nombre) when is_integer(nombre), do: create_log(count: nombre)
  def create_log(attrs \\ []) do
    nombre = Keyword.get(attrs, :count, 1)
    (1..nombre)
    |> Enum.each(fn x -> 
      text        = Keyword.get(attrs, :text, Rand.random_text(30))
      public      = Keyword.get(attrs, :public, true)
      inserted_at = Keyword.get(attrs, :inserted_at, now())
      data_log = %{public: public, text: text, owner_type: nil, owner_id: nil, inserted_at: inserted_at}
      data_log =
        if Keyword.has_key?(attrs, :owner) do
          Map.merge(data_log, %{owner_type: "user", owner_id: attrs[:owner].id})
          # Attention, ci-dessus, si ce n'est pas un User le propriétaire,
          # ça foire
        else
          otype = Keyword.get(attrs, :owner_type, "user")
          oid   = Keyword.get(attrs, :owner_id, make_simple_user().id)
          Map.merge(data_log, %{owner_type: otype, owner_id: oid})
        end
      data_log =
        if Keyword.has_key?(attrs, :created_by) do
          Map.put(data_log, :created_by, attrs[:created_by])
        else 
          creator = Keyword.get(attrs, :creator, make_simple_user())
          Map.put(data_log, :creator, creator)
        end
      Log.create(data_log)
    end)
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
      create_log(count: 2)
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
    
    test "peut filtrer par possesseur" do
      user = make_simple_user()
      create_log(text: "Le log de l'user", owner_type: "user", owner_id: user.id)
      create_log(count: 2)
      res = check_activities(owner: user, count: 1)
      assert( is_nil(res), res || "pas d'erreur")
    end

    test "peut filtrer par créateur" do
      user = make_simple_user()
      create_log(text: "Le log du créateur", creator: user)
      create_log(text: "Le log 2 du créateur", created_by: user.id)
      create_log(count: 5)
      res = check_activities(count: 7)
      assert(is_nil(res), res || "pas d'erreur")
      res = check_activities(creator: user, count: 2)
      assert(is_nil(res), res || "pas d'erreur")
    end

    test "peut filtrer par contenu littéral" do
      create_log(5)
      create_log(text: "Le texte recherché exact", count: 3)
      create_log(text: "Le texte recherché approximatif", count: 2)
      res = check_activities(content: "Le texte recherché exact", count: 3)
      assert(is_nil(res), res || "pas d'erreur")
      res = check_activities(content: "Le texte recherché", count: 5)
      assert(is_nil(res), res || "pas d'erreur")
    end

    test "peut filtrer par plusieurs données" do
      user = make_simple_user()
      create_log(owner: user)
      texte = "Le texte dans deux logs différents"
      create_log(text: texte)
      insat = ilya(3, :hour)
      create_log(inserted_at: insat)
      creator = make_simple_user()
      create_log(creator: creator)
      # Le log avec tout
      create_log(owner: user, text: texte, inserted_at: insat, creator: creator)
      data_searched = [
        count: 1,
        content: texte, owner: user, after: ilya(4, :hour), created_by: creator.id
      ]
      res = check_activities(count: 5)
      assert(is_nil(res), res || "pas d'erreur")
      res = check_activities(data_searched)
      assert(is_nil(res), res || "pas d'erreur")
    end

  end
  
end