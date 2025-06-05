# Code.require_file("test/support/test_helpers.ex")
# Code.require_file("test/support/feature_case.ex")
# Code.require_file("test/support/feature_methods/_main_.ex")

defmodule Mix.Tasks.Bddshot.Retreive do
  use Mix.Task

  @shortdoc "Remet l'état du site dans un état photographié"
  
  def run(params) do
    load_required_files()
    # IO.inspect(params, label: "PARAMS TASK")
    shotname = Enum.at(params, 0) || raise("Il faut donner le nom de la photographie à récupérer (nom dans test/x_bddshots)")
    path = Path.join(bddshots_folder(), "#{shotname}.dump")
    File.exists?(path) || raise("La photographie de bdd de test #{inspect shotname} est introuvable dans #{bddshots_folder()}…")
    
    # Tout est OK, on peut récupérer les données
    data = TestHelpers.bdd_load(shotname, true)
    IO.inspect(data, label: "\nDonnées de la photographie BdD")

    # Récupérer un simple user
    user = get_in_bdd_test("SELECT * FROM users WHERE privileges = 0 LIMIT 1")
    # Récupérer un administrateur du moment
    admin = get_in_bdd_test("SELECT * FROM users WHERE privileges = 64 LIMIT 1")
    # On essaie de récupérer un membre pour chaque collège, on le crée
    # si nécessaire
    membre_college1 = get_membre(college: 1)
    membre_college2 = get_membre(college: 2)
    membre_college3 = get_membre(college: 3)

    [user, admin, membre_college1, membre_college2, membre_college3] = 
    get_passwords_from([user, admin, membre_college1, membre_college2, membre_college3])

    IO.puts IO.ANSI.blue() <> """
    Tu peux maintenant jouer le site en mode de test dans
    l'état voulu.

        Simple user         : #{user.email || "inexistant"}\t#{user.password}
        Administrateur      : #{admin.email || "inexistant"}\t#{admin.password}
        Membre du collège 1 : #{membre_college1.email || "inexistant"}\t#{membre_college1.password}
        Membre du collège 2 : #{membre_college2.email || "inexistant"}\t#{membre_college2.password}
        Membre du collège 3 : #{membre_college3.email || "inexistant"}\t#{membre_college2.password}

    Lance le serveur avec :

        MIX_ENV=test mix phx.server
    
    Et rejoins l'adresse :  http://localhost:4002


    """ <> IO.ANSI.reset()
  end

  defp get_membre(options) do
    college = options[:college]
    {min, max} =
    case college do
      1 -> {0, credit_for(:seuil_college_two)}
      2 -> {credit_for(:seuil_college_two), credit_for(:seuil_college_three)}
      3 -> {credit_for(:seuil_college_three), 1000}
    end

    """
    SELECT u.name, u.email, mc.credit
    FROM users u
    JOIN member_cards mc ON mc.user_id = u.id
    WHERE credit >= #{min} AND credit < #{max}
    LIMIT 1
    """ 
    |> String.replace("\n", " ") 
    |> String.replace(~r/  +/, " ")
    |> get_in_bdd_test()
  end

  # Reçoit une requête SQL, la soumet à la base de données test et 
  # retourne la table du résultat.
  # 
  # @param {String} request SANS ";" à la fin
  defp get_in_bdd_test(request) do
    
    request = String.trim(request)

    {retour, exit_code} = System.cmd("psql", [
      "-U", "postgres",
      "-d", "ldq_test",
      "-t",
      "-A",
      "-F", ",",
      "-c", "SELECT row_to_json(u) FROM (#{request}) u;"
    ])
    if exit_code == 0 do
      # ok
      # IO.inspect(retour, label: "RETOUR DE BDD  ")
      if retour == "" do
        # raise "On aurait dû trouver un enregistrement dans la BdD Test avec :\n#{request}"
        %{name: "-Introuvable-", email: nil}
      else
        Jason.decode!(retour, keys: :atoms)
      end
    else
      # not ok
      IO.inspect(retour, label: "Retour error de cmd")
      raise "Je dois m'arrêter là"
    end

  end

  defp get_passwords_from(users) do
    password_path = Path.join(["test", "xtmp", "passwords_test"])
    passwords = :erlang.binary_to_term(File.read!(password_path))
    # IO.inspect(passwords, label: "\nPASSWORDS")
    Enum.map(users, fn user ->
      password = 
        if is_nil(user.email) do "" else
          Map.get(passwords, user.email, "motdepasse")
        end
      Map.put(user, :password, password)
    end)
  end

  defp credit_for(id) do
    LdQ.Evaluation.CreditCalculator.points_for(id)
  end

  defp bddshots_folder do
    Path.join(["test","x_bddshots"])
  end

  defp load_required_files do
    folder = "test/support/"
    # Les fichiers dans l'ordre de chargement requis
    [
      "random_methods.ex",
      "fixtures/library_fixtures.ex",
      "fixtures/comptes_fixtures.ex",
      "fixtures/procedures_fixtures.ex",
      "test_helpers.ex"
    ] |> Enum.each(fn file ->
      Code.require_file(Path.join(folder, file))
    end)
  end

end
