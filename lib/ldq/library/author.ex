defmodule LdQ.Library.Author do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "authors" do
    field :address, :string
    field :firstname, :string
    field :lastname, :string
    field :pseudo, :string
    field :email, :string
    field :url_perso, :string
    field :birthyear, :integer
    field :user_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(author, attrs) do
    author
    |> cast(attrs, [:firstname, :lastname, :pseudo, :email, :url_perso, :birthyear, :address])
    |> validate_required([:firstname, :lastname, :email])
  end
end
