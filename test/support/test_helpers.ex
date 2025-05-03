defmodule TestHelpers do

  alias Random.RandMethods, as: Rand
  import LdQ.ComptesFixtures
  alias LdQ.ProcedureFixture, as: FProc # create_procedure([...])
  alias LdQ.Site.Log
  alias LdQ.ProcedureMethods, as: Proc

  def w(str, color \\ :white) do
    params = case color do
      :white  -> [IO.ANSI.white(), str, IO.ANSI.reset()]
      :red    -> [IO.ANSI.red(), str, IO.ANSI.reset()]
      :blue   -> [IO.ANSI.blue(), str, IO.ANSI.reset()]
      :grey   -> IO.ANSI.format(["color:200,200,200", str, :reset])
    end
    IO.puts params
  end

  @doc """
  Pour pauser dans un pipe
  Note : hors d'un pipe, mettre nil en premier argument
  """
  def pause(sujet, quantite, unit \\ :seconde) do
    ms = case unit do
      :minute   -> quantite * 60
      :seconde  -> quantite
    end
    Process.sleep(ms * 1000)
    sujet
  end

  def now do
    NaiveDateTime.utc_now()
  end
  def ilya(nombre, unit) do
    NaiveDateTime.add(now(), - nombre, unit)
  end

  @doc """
  Permet de créer des logs avec ou sans des paramètres fournis

  @return {List} La liste des logs créés
  """
  def create_log(nombre) when is_integer(nombre), do: create_log(count: nombre)
  def create_log(attrs \\ []) do
    nombre = Keyword.get(attrs, :count, 1)
    (1..nombre)
    |> Enum.map(fn x -> 
      text        = Keyword.get(attrs, :text, "<p>" <> Rand.random_text(30) <> "</p>")
      public      = Keyword.get(attrs, :public, true)
      inserted_at = Keyword.get(attrs, :inserted_at, Rand.random_time(:before, ilya(1, :day)) )
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
      {:ok, log} = Log.create(data_log)
      log
    end)
  end

  @doc """
  Voir LdQ.Procedure.get_procedure/1
  """
  def get_procedure(params) do
    Proc.get_procedure(params)
  end

  @doc """
  Voir LdQ.ProcedureFixture
  """
  def create_procedure(params) do
    FProc.create_procedure(params)
  end
  
end
