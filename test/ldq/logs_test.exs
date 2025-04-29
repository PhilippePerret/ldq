defmodule LdQ.LogsTest do
  use LdQ.DataCase
  
  alias LdQ.Site.Log
  alias LdQ.ComptesFixtures, as: F
  alias Random.RandMethods, as: Rand

  def new_user(attrs \\ %{}) do
    F.user_fixture(attrs)
  end

  describe "add" do
    test "avec les bonnes informations, ajoute un nouveau log" do
      owner = new_user(%{name: "John Steed"})

      dlog = %{
        text: "Le premier log de #{owner.name}",
        owner_type: "user",
        owner_id: owner.id,
        public: true,
        creator: owner
      }

      assert {:ok, _} = Log.add(dlog)
    end

    test "on peut fournir l'owner lui-même" do
      owner = new_user(%{name: "Selma Jezkova"})
      dlog = %{
        owner: owner,
        text: "Le deuxième log est de Selma",
        creator: owner
      }
      assert {:ok, _} = Log.add(dlog)
    end

    test "on doit fournir un texte, toujours" do
      owner = new_user(%{name: "Bill Houston"})
      dlog = %{
        owner: owner,
        creator: owner,
        public: true
      }
      {res, changeset} = Log.add(dlog)
      assert res == :error
      assert %{
        text: ["can't be blank"]
      } = errors_on(changeset)
    end

    test "on doit fournir un créateur, toujours" do
      owner = new_user(%{name: "Selma Jezkova"})
      dlog = %{
        owner: owner,
        text: "Le deuxième message de Selma, sans créateur",
        public: false
      }

      {res, changeset} = Log.add(dlog)
      assert res == :error
      assert %{
        created_by: ["can't be blank"]
      } = errors_on(changeset)
    end

  end #/ describe "add"

  describe "get_lasts_public" do

    test "avec 10, retourne les dix derniers messages" do
      create_logs(10_000, [public: 15]) # S'arrêtera lorsqu'il y aura 15 logs public
      # |> IO.inspect(label: "\nRésultat de la création")
      lasts = Log.get_lasts_public(10)
      # |> IO.inspect(label: "Les 10 messages retournés")
      # Pour comparer, on va prendre les dix derniers publics

      assert(Enum.count(lasts) == 10, "On aurait dû recevoir 10 messages")

      # Ce doit être les bons messages, et dans le bon ordre
      publics = 
        Log.get_all()
        |> Enum.filter(fn log -> log.public end)
        |> Enum.sort_by(&(&1.inserted_at), {:desc, Date})
        # |> IO.inspect(label: "Les publics dans l'ordre")
        |> Enum.with_index()
        |> Enum.each(fn {log, index} ->
          if index < 10 do
            assert log.id == Enum.at(lasts, index).id
          end
        end)

    end

  end


  def create_logs(nombre, options) do
    create_log(%{count: 0, count_public: 0, list: [], creator: new_user()}, nombre, options)
  end
  def create_log(tableres, nombre_expected, options) when tableres.count < nombre_expected do
    if options[:public] && tableres.count_public == options[:public] do
      tableres
    else
      public = Enum.random([true, false])
      texte = 
        if public do
          "Message public #{tableres.count_public + 1} / #{tableres.count + 1}"
        else
          "Message non public #{tableres.count + 1} / #{tableres.count + 1}"
        end
      dlog = %{
        text: texte,
        public: public,
        creator: tableres.creator, 
        inserted_at: Rand.random_time()
      }
      Log.add(dlog)
      tableres = %{tableres | list: tableres.list ++ [dlog]}
      tableres = %{tableres | count: tableres.count + 1}
      tableres = %{tableres | count_public: tableres.count_public + (dlog.public && 1 || 0)}
      create_log(tableres, nombre_expected, options)
    end
  end
end