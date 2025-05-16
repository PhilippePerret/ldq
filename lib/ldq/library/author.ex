defmodule LdQ.Library.Author do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "authors" do
    field :address, :string
    field :firstname, :string
    field :lastname, :string
    field :name, :string
    field :pseudo, :string
    field :email, :string
    field :sexe, :string, default: "H"
    field :url_perso, :string
    field :birthyear, :integer
    # field :user_id, :binary_id

    belongs_to :user, LdQ.Comptes.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(author, attrs) do
    attrs = attrs
    |> add_name_property()
    
    author
    |> cast(attrs, [:name, :firstname, :lastname, :pseudo, :email, :url_perso, :birthyear, :address, :sexe, :user_id])
    |> validate_required([:name, :sexe, :firstname, :lastname, :email])
  end

  def add_name_property(attrs) do
    Map.put(attrs, "name", String.trim("#{attrs["firstname"]} #{attrs["lastname"]}"))
  end
end
