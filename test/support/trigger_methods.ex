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


end