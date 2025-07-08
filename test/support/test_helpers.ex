defmodule TestHelpers do

  alias LdQ.Repo
  alias LdQ.Comptes
  alias LdQ.Comptes.User
  alias Random.Methods, as: Rand
  import LdQ.ComptesFixtures
  alias LdQ.ProcedureFixture, as: FProc # create_procedure([...])
  alias LdQ.Site.Log
  alias LdQ.ProcedureMethods, as: Proc

  # Enregistre une photographie de l'état actuel de l'application
  # Cf. La méthode bdd_dump pour le détail
  def bddshot(name, data) do
    bdd_dump(name, data)
    IO.puts [IO.ANSI.blue(), "\n 📸 Photographie “#{name}” effectuée", IO.ANSI.reset()]
  end
  
  @doc """
  Applique à la base de données la photographie exacte qui porte
  le nom +name+ et retourne les données enregistrées.

  @param {String} name Le nom (chemin relatif) de la photographie de
  la table dans test/xbddshots

  @return {Map} Les données enregistrées avec la photographie. Cf
  l'endroit où a été faite la photographie — en cherchant :
  « bbdshot("<name>", » noter : sans parenthèse fermante, avec une
  virgule — pour voir quelles sont ces données
  """
  def bddshot(name) when is_binary(name) do
    bdd_load(name)
  end
  @doc """
  Procède à une copie de la base de test actuelle
  C'est ce que j'appelle les « Photographies de la BdD ». Grâce à 
  elles on peut repartir de n'importe quel point des tests 
  d'intégration.

  Certaines propriétés peuvent avoir des sessions, il faut les 
  supprimer avant enregistrement.
  """
  @prop_with_session [:user, :author, :admin, :super_admin, :super_user]
  def bdd_dump(dump_name, data) do
    data = @prop_with_session
    |> Enum.reduce(data, fn key, d -> 
      if Map.get(data, key) do
        if Map.get(data[key], :session) do
          new_value = Map.delete(data[key], :session)
          Map.put(d, key, new_value)
        else d end
      else d end
    end)
    path = dump_path(dump_name)
    System.cmd("pg_dump", ["-Fc", "-dldq_test", ~s(-f#{path})])
    data_path = "#{path}.data"
    File.write!(data_path, :erlang.term_to_binary(data))
  end
  

  @tables [
      LdQ.Procedure,
      LdQ.Notification,
      LdQ.Library.Book,
      # LdQ.Library.Book.Evaluation,
      # LdQ.Library.Book.Specs,
      # LdQ.Library.Book.MiniCard,
      LdQ.Comptes.User,
      LdQ.Library.Author,
      LdQ.Library.Publisher,
      LdQ.Tests.Mails,
      LdQ.Core.Trigger
    ]

  @doc """
  Pour tout ré-initialiser à chaque test
  """
  def reset_all do
    # Puisqu'on n'utilise plus la sandbox pour pouvoir faire des
    # photographies de la BdD, on doit forcer le vidage de la base 
    # de données avant chaque test.
    TestHelpers.bdd_reset()
    # Supprimer tous les mails
    # Note : si des mails sont utiles pour un test suivant, il faut
    # les enregistrer au moment de figer l'état de la base de données
    # (avec bdd_dump) et récupérer cet état avec bdd_load/1
    Feature.MailTestMethods.exec_delete_all_mails()
    # Vider le dossier des uploads
    uploads_folder = Path.join(["priv","static","uploads"])
    File.rm_rf!(uploads_folder)
    File.mkdir!(uploads_folder)
    # Vider le fichier des logs de triggers
    pth = Path.join(["priv/logs/trigger-test.log"])
    File.exists?(pth) && File.rm(pth)
  end

  @doc """
  Réinitialisation de la BdD de test, avant chaque test d'intégration
  cette fonction est appelée. Elle vide les tables ci-dessus.

  NB : Les tables des pages ne sont pas remises à zéro.
  """
  def bdd_reset do
    Enum.each(@tables, fn table ->
      Repo.delete_all(table)
    end)
  end

  @doc """
  Restaure la photographie +dump_name+ de la base et retourne les 
  données associées à cette table.

  @return {Map} Une table des données enregistrées avec l'état de la
  base.
  """
  def bdd_load(dump_name, for_task \\ false) do
    dump_path = dump_path(dump_name)
    if File.exists?(dump_path) do
      System.cmd("pg_restore", ["--clean", "--no-owner", "-dldq_test", dump_path])
    else
      raise "Dump introuvable : #{dump_name}"
    end

    data_path = "#{dump_path}.data"
    if File.exists?(data_path) do
      data = :erlang.binary_to_term(File.read!(data_path))
      # On ajoute l'instance de la procédure si son identifiant
      # est défini (seulement quand on est en mode de test normal,
      # pas quand on remet l'état de la BdD avec la mix-task)
      data =
        if for_task do data else
          # En test
          if Map.get(data, :procedure_id) do
            Map.put(data, :procedure, LdQ.Procedure.get( Map.get(data, :procedure_id)))
          else data end
        end
      data
    else
      raise "Data du dump #{dump_name} introuvable (#{data_path})"
    end
  end

  def dump_path(name) do
    "#{dumps_folder()}/#{name}.dump"
  end
  def dumps_folder do
    Path.absname(Path.join(["test", "x_bddshots"]))
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
  
  @doc """
  Crée plusieurs users, dont certains membres
  Crée plusieurs livres en évaluation
  """
  def create_users_members_and_books(_params \\ %{}) do
    make_simple_users(20) # peu importe qui
    membres = make_membres(20, %{with_credit: true, with_books: true})
    passwords = 
      membres
      |> Enum.reduce(%{}, fn member, table ->
        Map.put(table, member.email, member.password)
      end)
    save_passwords_of(passwords)

  end

  @doc """
  Ajoute le mot de passe à la table de l'user +user+
  Raise une erreur si le mot de passe ne peut pas être trouvé
  NON, car il y a plein de cas où la non définition du mot de passe 
  ne pose pas de problème.

  @param {LdQ.Comptes.User} user L'utilisateur auquel il faut ajouter le mot de passe
  """
  def add_password_to!(%User{} = user) do
    password = get_password_of(user.email) || universal_password()
    struct(user, password: password)
  end

  @doc """
  Consignation d'une table de mots de passe qui pourront être
  récupérés par get_password_of/1
  """
  def save_passwords_of(emails_to_passwords) when is_map(emails_to_passwords) do
    passwords = Map.merge(get_passwords(), emails_to_passwords)
    File.write!(passwords_path(), :erlang.term_to_binary(passwords))
  end
  @doc """
  Consignation d'un mot de passe, qui pourra être récupéré par 
  get_password_of/1
  """
  def save_password_of(email, password) do
    save_passwords_of(%{email => password})
  end
  # ATTENTION user ici doit avoir une propriété :password
  def save_password_of(user) when is_struct(user, User) do
    user[:password] || raise("L'user doit définir son mot de passe")
  end
  def get_password_of(email) when is_binary(email) do
    Map.get(get_passwords(), email, nil)
  end
  def get_password_of(user) do
    get_password_of(user.email)
  end
  # @return {Map} Retourne tous les passwords
  defp get_passwords do
    path = passwords_path()
    if File.exists?(path) do
      File.read!(path) |> :erlang.binary_to_term()
      # |> IO.inspect(label: "PASSWORDS")
    else
      %{}
    end
  end
  def passwords_path do
    Path.join(~w(test xtmp passwords_test))
  end

end
