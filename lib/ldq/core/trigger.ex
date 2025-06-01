defmodule LdQ.Core.Trigger do
  @moduledoc """
  Module qui gère les TRIGGERs. Les TRIGGERs, comme leur nom l'indi-
  que, sont des déclencheurs d'alertes lorsque des choses ne se sont
  pas passés comme il devrait. Cela permet d'assurer le bon fonction-
  nement de l'application.
  Exemple typique : lorsqu'un livre est mis en évaluation, on décide
  qu'il faut au maximum 6 mois pour l'évaluer et lui attribuer ou non
  le label Lecture de Qualité. Sans trigger, on pourrait passer sans 
  s'en apercevoir cette limite.
  Fonctionnement par rapport à cet exemple : au moment de la mis en
  évaluation d'un livre par un administrateur, un trigger de type 
  donné est créé. On n'y touche pas pendant 6 mois, à l'heure près.
  Six mois plus tard, à l'heure près, le "trigger daemon" demande à
  ce module la relève des triggers du jour et de l'heure. Le trigger
  placé six mois plus tôt est récupéré et analysé. Si le livre a bien
  été évalué, le trigger est tout simplement détruit. Dans le cas
  contraire, l'administration est notifée et le trigger est reconduit
  pour la période deux fois moins longue (ou définie par les données)
  """
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  alias LdQ.Core
  alias LdQ.Core.TriggerAbsdata, as: AbsData

  
  @doc """
  @api
  Poser un trigger, c'est-à-dire l'enregistrer pour qu'il se déclen-
  che le moment venu.

  @params {Map} attrs Les données obligatoires. Note : on s'assure que
                les :required_data définies dans @triggers_data 
                soient définies
  @params {Keyword} options Les options (inutilisé pour le moment)
  """
  def pose_trigger(trigger_type, data \\ %{}, options \\ []) do
    # Données absolues du trigger (cf. trigger_absdata.ex)
    absdata = AbsData.data(trigger_type)
    # Vérifier la présence des informations requises
    if absdata.required_data do
      absdata.required_data |> Enum.each(fn {key, msg} ->
        data[key] || raise(ArgumentError, "Data manquante : #{key} (#{msg})")
      end)
    end
    options[:marked_by] || raise(ArgumentError, "Il faut donner l'ID du marqueur de ce trigger, en options (options[marked_by: <...>])")

    # On compose les données du trigger
    reldata = %{
      type:         trigger_type,
      trigger_at:   date_dans(absdata.duration),
      data:         data,
      priority:     absdata.priority,
      uniq_scope:   "evalbook:#{data.book_id}",
      marked_by:    options[:marked_by]
    }
    # On crée véritablement le trigger
    Core.create_trigger!(reldata)
  end

  @doc """
  Méthode principale d'évaluation du trigger. C'est elle qui détermi-
  ne si l'opération est positive ou négative.

  @param {Trigger} trigger Le trigger enregistré
  
  @return :ok ou {:error, raison} (par exemple {:error, "Il manque 4 membres du collège 2"})
  """
  def eval_trigger(trigger) do
    # On commence par ajouter au trigger ses propriétés particulière
    # (le livre book, la procédure, l'user, etc.)
    trigger = add_own_properties(trigger)
    |> IO.inspect(label: "TRIGGER")
  end

  def check_trigger("evaluation-book", trigger) do
    book = trigger.book
  end
  def check_trigger(trig_type, trigger) do
    raise "Le type #{inspect trig_type} est inconnu"
  end

  defp add_own_properties(trigger) do
    absdata = AbsData.data(trigger)
    absdata =
      if absdata.required_data[:book_id] do
        LdQ.Library.Book.get!(trigger.data.book_id)
      else absdata end
    absdata =
      if absdata.required_data[:procedure_id] do
        LdQ.Procedure.get!(trigger.data.procedure_id)
      else absdata end

    absdata
  end

  @doc """
  @api
  Supprimer un trigger.

  Noter que dans le processus normal, cette fonction n'a pas à être 
  appelée puisque les triggers sont automatiquement détruits, qu'ils
  aient ou non produits un succès (ils sont remplacés, en cas
  d'échec, par un trigger actualisé)
  """
  def remove_trigger(params) do
  end

  @doc """
  Pour reconduire le trigger, en cas d'échec.

  Par défaut, la durée est la :duration définie divisisée par deux.
  Mais elle peut être définie explicitement dans la propriété 
  :recond_duration
  """
  def reconduit_trigger(trigger) do
    absdata = AbsData.data(trigger)
    trigger = Map.merge(trigger, %{
      priority:   trigger.priority + 1,
      trigger_at: date_dans(absdata.recond_duration)
    })
  end

  @doc """
  @api
  Relève les triggers courants dans la base et les exécute

  """
  def fetch_and_execute do
    fetch_current_triggers()
    |> remove_current_triggers()
    |> execute_triggers()
  end

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "triggers" do
    field :type, :string
    field :uniq_scope, :string
    field :trigger_at, :naive_datetime
    field :data, :string
    field :marked_by, :binary_id
    # Niveau de priorité. Il augmente à chaque reconduction du
    # trigger, pour le rendre de plus en plus intense. Il faut 
    # vraiment espérer qu'au bout du 3e déclenchement, l'opération
    # soit vraiment exécutée.
    field :priority, :integer

    field :book, :map, virtual: true
    field :procedure, :map, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trigger, attrs) do
    attrs = attrs 
    |> Phil.Map.ensure_keys_string() 
    |> json_encode_data()

    trigger
    |> cast(attrs, [:type, :data, :uniq_scope, :trigger_at, :priority, :marked_by])
    |> validate_required([:type, :data, :uniq_scope, :trigger_at, :priority])
    |> unique_constraint(:uniq_scope)
  end

  defp json_encode_data(attrs) do
    %{attrs | "data" => Jason.encode!(attrs["data"] || %{})}
  end


  # Fonction qui relève dans la table triggers tous les triggers qui
  # doivent être exécutés (donc tous les triggers plus vieux que 
  # maintenant)
  defp fetch_current_triggers do
    now = NaiveDateTime.utc_now()
    from(t in __MODULE__, where: t.trigger_at < ^now)
    |> Repo.all()
  end

  # On détruit tout de suite les triggers (on ne laisse rien trainer
  # même en cas de problème)
  defp remove_current_triggers(triggers) do
    now = NaiveDateTime.utc_now()
    from(t in __MODULE__, where: t.trigger_at < ^now)
    |> Repo.delete_all()
    triggers # pour le chainage
  end

  defp execute_triggers(triggers) do
    IO.inspect(triggers, label: "TRIGGERS À TRAITER")
    triggers 
    |> Enum.each(fn trigger ->
      try do
        execute_trigger(trigger.type, trigger)
      rescue 
        error -> log_trigger_error(trigger, error)
      end
    end)
  end

  # --- Exécute le trigger de type voulu ---


  # Quand le quorum du collège 1 n'a toujours pas été atteint sur
  # un livre. Une notification est faite à l'administrateur et le
  # trigger est reposé.
  # TODO note : si on définit tout dans @triggers_data, tout sera 
  # centralisé et on aura besoin que d'une seule fonction. Après
  # tout, normalement, un déclenchement devrait toujours provoquer
  # une notification, l'envoi d'un mail peut-être et la reconduite
  # du trigger (peut-être avec un délai plus court ?).
  defp execute_trigger("deadline-quorum-college-1", trigger) do
    raise "à traiter"
    notify(trigger)
    reconduit_trigger(trigger)
  end

  def notify(trigger) do
    # TODO
  end

  # Type de trigger inconnu
  defp execute_trigger(unknown_type, trigger) do
    raise """
      Le type de trigger #{inspect unknown_type} est inconnu.
      Pour pallier le problème, il faut créer la fonction :

        def execute_trigger("#{unknown_type}", trigger) do
          ... traitement ...
        end

        Dans le fichier #{__ENV__.file}
    """
  end




  def log_trigger_error(trigger, error) do
    IO.puts "Je dois apprendre à logger l'erreur fatale : #{inspect error} \nsur le trigger #{inspect trigger}"
  end


  # @return la date dans le temps +duration+
  # @param {Duplet {quantity, unity}} duration La durée définie par 
  # un duplet
  defp date_dans(duration) do
    {unity, quantity} = duration

    {unity, quantity} = if unity == :month do
      {:day, quantity * 30}
    else duration end
    NaiveDateTime.add(NaiveDateTime.utc_now(), quantity, unity)
  end
end
