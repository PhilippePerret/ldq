defmodule TestHelpers do

  alias LdQ.Repo
  alias LdQ.Comptes
  alias Random.RandMethods, as: Rand
  import LdQ.ComptesFixtures
  alias LdQ.ProcedureFixture, as: FProc # create_procedure([...])
  alias LdQ.Site.Log
  alias LdQ.ProcedureMethods, as: Proc

  @doc """
  Procède à une copie de la base test actuelle
  """
  def bdd_dump(dump_name, data) do
    path = dump_path(dump_name)
    System.cmd("pg_dump", ["-Fc", "-dldq_test", ~s(-f#{path})])
    data_path = "#{path}.data"
    File.write!(data_path, :erlang.term_to_binary(data))
  end

  @tables [
      LdQ.Procedure,
      LdQ.Notification,
      LdQ.Library.Book.Evaluation,
      LdQ.Library.Book.Specs,
      LdQ.Library.Book.MiniCard,
      LdQ.Comptes.User,
      LdQ.Library.Author,
      LdQ.Library.Publisher
    ]

  def bdd_reset() do
    Enum.each(@tables, fn table ->
      Repo.delete_all(table)
    end)
  end

  def bdd_dump_with_sandbox(dump_name, data) do
    path = dump_path(dump_name)

    tables = @tables
    # Note : on ne prend pas Pages et PagesLocales

    truncate_lines = for module <- Enum.uniq(tables), do: "TRUNCATE TABLE #{module.__schema__(:source)} CASCADE;"
    inserts =
      for module <- tables, record <- Repo.all(module) do
        table = module.__schema__(:source)
        fields = module.__schema__(:fields)
        values = Enum.map(fields, &Map.get(record, &1))

        field_list = Enum.map(fields, &~s("#{&1}")) |> Enum.join(", ")
        value_list =
          values
          |> Enum.map(&dump_sql_value/1)
          |> Enum.join(", ")

        "INSERT INTO #{table} (#{field_list}) VALUES (#{value_list});"
      end

    File.write!(path, Enum.join(truncate_lines ++ inserts, "\n"))

    data_path = "#{path}.data"
    File.write!(data_path, :erlang.term_to_binary(data))
  end

  defp dump_sql_value(nil), do: "NULL"
  defp dump_sql_value(%NaiveDateTime{} = dt), do: "'#{NaiveDateTime.to_string(dt)}'"
  defp dump_sql_value(%DateTime{} = dt), do: "'#{DateTime.to_string(dt)}'"
  defp dump_sql_value(%Date{} = d), do: "'#{Date.to_string(d)}'"
  defp dump_sql_value(%Time{} = t), do: "'#{Time.to_string(t)}'"
  defp dump_sql_value(binary) when is_binary(binary), do: "'#{String.replace(binary, "'", "''")}'"
  defp dump_sql_value(%{} = map), do: "'#{Jason.encode!(map)}'"
  defp dump_sql_value(list) when is_list(list), do: "'{" <> Enum.join(list, ",") <> "}'"
  defp dump_sql_value(other), do: "#{other}"

  @doc """
  Restaure la photographie +dump_name+ de la base 

  @return {Map} Une table des données enregistrées avec l'état de la
  base.
  """
  def bdd_load(dump_name) do
    dump_path = dump_path(dump_name)
    if File.exists?(dump_path) do
      System.cmd("pg_restore", ["--clean", "--no-owner", "-dldq_test", dump_path])
      # Repo.query!(File.read!(dump_path))
      # for query <- String.split(File.read!(dump_path), ";", trim: true), String.trim(query) != "" do
      #   Repo.query!(query <> ";")
      # end      
    else
      raise "Dump introuvable : #{dump_name}"
    end

    data_path = "#{dump_path}.data"
    if File.exists?(data_path) do
      :erlang.binary_to_term(File.read!(data_path))
    else
      raise "Data du dump #{dump_name} introuvable (#{data_path})"
    end
  end

  def dump_path(name) do
    "#{dumps_folder()}/#{name}.dump"
  end

  def dumps_folder do
    Path.absname(Path.join(["test", "xbdd_dumps"]))
  end

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
