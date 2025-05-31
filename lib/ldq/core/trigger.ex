defmodule LdQ.Core.Trigger do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

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
    field :priority, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(trigger, attrs) do
    trigger
    |> cast(attrs, [:type, :data, :uniq_scope, :trigger_at, :priority, :marked_by])
    |> validate_required([:type, :data, :uniq_scope, :trigger_at, :priority])
    |> unique_constraint(:uniq_scope)
  end


  # Fonction qui relève dans la table triggers tous les triggers qui
  # doivent être exécutés (donc tous les triggers plus vieux que 
  # maintenant)
  defp fetch_current_triggers do
    now = NaiveDateTime.utc_now()
    from(t in __MODULE__, where t.trigger_at < ^now)
    |> Repo.all()
  end

  # On détruit tout de suite les triggers (on ne laisse rien trainer
  # même en cas de problème)
  defp remove_current_triggers(triggers) do
    now = NaiveDateTime.utc_now()
    from(t in __MODULE__, where t.trigger_at < ^now)
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
  defp execute_trigger("deadline-quorum-college-1", trigger) do
    raise "à traiter"
  end

  defp execute_trigger(unknown_type, trigger) do
    raise """
      Le type de trigger #{inspect unknown_type} est inconnu.
      Pour pallier le problème, il faut créer la fonction :

        def execute_trigger("#{unknown_type}", trigger) do
          ... traitement ...
        end

        Dans le fichier #{__FILE__}
    """
  end




  def log_trigger_error(trigger, error) do
    IO.puts "Je dois apprendre à logger l'erreur fatale : #{inspect error} \nsur le trigger #{inspect trigger}"
  end
end
