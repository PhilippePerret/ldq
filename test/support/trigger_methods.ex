defmodule LdQ.TriggerTestMethods do

  # Pour les assertions
  use LdQWeb.FeatureCase, async: false

  alias LdQ.Repo
  import Ecto.Query

  alias LdQ.Core.{Trigger, TriggerAbsdata}

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
    last_lines = Phil.PFile.last_lines(logpath(), 10)
    IO.inspect(last_lines, label: "")
    resultat =
      last_lines
      |> Enum.reduce(%{ok: false, nombre: 0}, fn line, res ->
        # On décompose la ligne de log
        [time, content] = Enum.split(line, "\t", [trim: true, parts: 2])
        time = NaiveDateTime.from_iso8601!(time)
        res = 
          if params[:after] && NaiveDateTime.after?(params[:after], time) do
            %{ok: false, nombre: res.nombre}
          else res end

        res
      end)
    count = params[:count] || 1

    assert(resultat.nombre == count, "On aurait dû trouver #{count} log(s) correspondant aux paramètres, on en a trouvé #{resultat.nombre}. Paramètres : #{inspect params}")
  end
  def logpath do
    Path.join(["priv/log/trigger-test.log"])
  end

  def read_x_last_lines(path, x, max_len \\ 1000) do
    {:ok, fd} = :file.open(path, [:read, :binary])
    {:ok, size} = :file.read_file_info(path) |> then(&{:ok, &1.size})
    start = max(size - (x + 10) * max_len, 0)
    start = if start < 0, do: 0, else: start
    :file.position(fd, start)
    {:ok, data} = :file.read(fd, size - start)
    data |> to_string() |> String.split("\n") |> Enum.take(-x)
  end
end