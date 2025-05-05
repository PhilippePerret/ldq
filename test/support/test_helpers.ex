defmodule TestHelpers do

  alias LdQ.Comptes
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
    ms = 
      case unit do
        :minute   -> quantite * 60
        :seconde  -> quantite
      end * 1000
    ms = if is_float(ms), do: trunc(ms), else: ms
    # On peut s'arrêter
    Process.sleep(ms)
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
  def create_log(foo \\ [])
  def create_log(nombre) when is_integer(nombre), do: create_log(count: nombre)
  def create_log(attrs) do
    nombre = Keyword.get(attrs, :count, 1)
    (1..nombre)
    |> Enum.map(fn _x -> 
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
  Rafraichit l'user en prenant ses données dans la table, en conser-
  vant sa session et sa procédure si elles existent. Ainsi que :
  :last_point_test (son dernier point de check)
  """
  def refresh_user(user) when is_map(user) do
    get_user(
      id:         user.id, 
      session:          Map.get(user, :session, nil), 
      procedure:        Map.get(user, :procedure, nil),
      last_point_test:  Map.get(user, :last_point_test, nil)
    )
  end

  @doc """
  Retourne un User rafraichi, relevé dans la table.

  Mais la grand différence entre get_user(keyword) et get_user(binary)
  c'est que la première retourne une Map (contrairement à la seconde
  qui retourne un structure %User{}) à laquelle sera ajouté :session
  et :procedure.
  On peut utiliser, aussi, plus facilement, la méthode refresh_user/1
  
  @param {Keyword} params
    params[:id]   Identifiant de l'user
    params[:session]  Sa session courante
    params[:procedure]  Sa procédure courante (if any)
    params[:last_point_test] {NaiveDateTime} Son dernier point de check
  """
  def get_user(params) when is_list(params) do
    user = get_user(params[:id])
    if params[:session] || params[:procedure] || params[:last_point_test] do
      user = Map.from_struct(user)
      user = Map.delete(user, :__meta__)
      user = Map.put(user, :session, params[:session])
      user = Map.put(user, :last_point_test, params[:last_point_test])
      Map.put(user, :procedure, params[:procedure])
    else 
      user 
    end
  end
  def get_user(user_id) when is_binary(user_id) do
    Comptes.get_user!(user_id)
  end

  @doc """
  Voir LdQ.ProcedureFixture
  """
  def create_procedure(params) do
    FProc.create_procedure(params)
  end
  
end
