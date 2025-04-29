defmodule LdQ.Site.Log do
  use Ecto.Schema
  
  alias LdQ.Repo
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "logs" do
    field :public, :boolean, default: false
    field :text, :string
    field :owner_type, :string
    field :owner_id, :binary
    
    belongs_to :creator, LdQ.Comptes.User, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(log, attrs) do
    attrs = attrs
    |> treate_owner()
    |> treate_creator()

    log
    |> cast(attrs, [:text, :owner_type, :owner_id, :public, :created_by, :inserted_at])
    |> validate_required([:text, :public, :created_by])
  end


  @doc """
  Pour ajouter une ligne d'historique

  LdQ.Log.add(%{})

  @param {Map} data Données
  """
  def create_log(attrs) do
    %__MODULE__{}
    |> changeset( attrs)
    |> Repo.insert()
  end
  def add(data), do: create_log(data)

  @doc """
  Retourne les +nombre+ derniers logs publics

  @param {Integer} nombre Nombre de logs à retourner

  @return {List>Map} Retourne la liste des données des logs.
  """
  def get_lasts_public(nombre \\ 10) do
    from(log in __MODULE__, 
      where: log.public == true, 
      limit: ^nombre,
      order_by: [desc: log.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload(:creator)
  end

  def get_all() do
    Repo.all(__MODULE__)
  end



  # --- Sous-méthodes ---

  defp treate_creator(attrs) do
    if attrs[:creator] do
      Map.put(attrs, :created_by, attrs[:creator].id)
    else attrs end
  end

  # Dans le log, on peut indiquer simplement le :owner et cette fonction
  # en déduira le :owner_type et le :owner_id
  defp treate_owner(attrs) do
    if attrs[:owner] do
      add_owner(attrs, attrs[:owner])
    else attrs end
  end
  defp add_owner(attrs, owner) when is_struct(owner, LdQ.Comptes.User) do
    Map.merge(attrs, %{owner_type: "user", owner_id: owner.id})
  end
  defp add_owner(attrs, owner) when is_struct(owner, LdQ.Book) do
    Map.merge(attrs, %{owner_type: "book", owner_id: owner.id})
  end
  defp add_owner(attrs, owner) do
    Map.merge(attrs, %{owner_type: "unknown", owner_id: nil})
  end
end
