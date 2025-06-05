defmodule LdQ.TriggerTestMethods do

  # Pour les assertions
  use LdQWeb.FeatureCase, async: false

  alias LdQ.Repo
  import Ecto.Query

  alias LdQ.Core.{Trigger} # , TriggerAbsdata

  @doc """
  S'assure qu'un trigger existe, avec les paramètres +params+

  @params {Keyword} params La table des paramètres à trouver
    :after    Le trigger doit avoir été placé après ce temps
    :count    {Integer} Le nombre de triggers à trouver (1 par défaut)
    :data     {Map} Les données doivent contenir les données fournies
  """
  def assert_exists(params) do
    query = from(t in Trigger, select: t)

    query = if params[:after] do
      where(query, [t], t.inserted_at > ^params[:after])
    else query end

    query = if params[:type] do
      where(query, [t], t.type == ^params[:type])
    else query end

    all_triggers = 
      Repo.all(query) 
      |> Enum.map(fn trig -> %{trig | data: Jason.decode!(trig.data, keys: :atoms) } end)

    triggers = if params[:data] do
      Enum.filter(all_triggers, fn trig -> 
        Enum.reduce(params[:data], true, fn {prop, value}, coll ->
          if Map.get(trig.data, prop) != value do
            false
          else coll end
        end)
      end)
    else 
      all_triggers 
    end

    nombre_triggers = Enum.count(triggers)
    nombre_expected = params[:count] || 1

    
    detail =
    if params[:debug] && nombre_triggers != nombre_expected do
      triggers = Enum.map(all_triggers, fn trig -> inspect trig end)
      "Triggers dans la base : #{Enum.count(triggers)} : #{inspect triggers}"
    else 
      "(ajoute debug: true aux paramètres pour voir le détail)"
    end

    assert(nombre_triggers == nombre_expected, "On devait trouver #{nombre_expected} trigger(s) avec les paramètres : #{inspect params}, on en a trouvé : #{nombre_triggers}.\n#{detail}")

  end

  def assert_log(params) do
    {:ok, last_lines} = Phil.PFile.last_lines(logpath(), 10)

    params = Keyword.put(params, :trig_type, params[:trig_type] || params[:type])

    resultat =
      last_lines
      |> Enum.reduce(%{ok: false, nombre: 0, errors: []}, fn line, res ->
        # On décompose la ligne de log
        [time, typeop, typetrig, content] = String.split(line, "\t", [trim: true, parts: 4])
        time = NaiveDateTime.from_iso8601!(time)
        cond do 
        params[:after] && not NaiveDateTime.after?(time, params[:after]) ->
          %{ok: false, nombre: res.nombre, errors: res.errors ++ ["Log avant la date limite"]}
        params[:type_op] && (typeop != params[:type_op]) ->
          %{ok: false, nombre: res.nombre, errors: res.errors ++ ["Le type d'opération ne correspond pas (attendu: #{params[:type_op]}, trouvé: #{typeop})"]}
        params[:trig_type] && (typetrig != params[:trig_type]) ->
          %{ok: false, nombre: res.nombre, errors: res.errors ++ ["Le type de trigger ne correspond pas (attendu: #{params[:trig_type]}, trouvé: #{typetrig})"]}
        params[:content] && log_not_contains(content, params[:content]) ->
          %{ok: false, nombre: res.nombre, errors: res.errors ++ ["Le log du trigger ne contient pas le texte recherché"]}
        true ->
          # ok
          %{ok: true, nombre: res.nombre + 1, errors: res.errors}
        end
      end)
    count = params[:count] || 1

    assert(resultat.nombre == count, "On aurait dû trouver #{count} log(s) correspondant aux paramètres, on en a trouvé #{resultat.nombre}. Paramètres : #{inspect params}")
  end
  def logpath do
    Path.join(["priv/logs/trigger-test.log"])
  end

  defp log_not_contains(contenu, search) when is_binary(search), do: log_not_contains(contenu, [search])
  defp log_not_contains(contenu, searchs) when is_list(searchs) do
    contain = 
      Enum.reduce(searchs, true, fn search, found ->
        search = Regex.escape(search)
        search = ~r/#{search}/
        if contenu =~ search do
          found
        else 
          false 
        end
      end)
    !contain
  end

end