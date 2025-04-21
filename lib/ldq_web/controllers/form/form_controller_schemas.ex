
defmodule LdQ.Candidat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "candidats" do
    field :user_id, :binary
    field :raison, :string
    field :has_genres, :boolean
    field :genres, {:array, :string}
  end

  @doc false
  def changeset(candidat, attrs) do
    candidat 
    |> cast(attrs, [:user_id, :raison, :has_genres, :genres])
    |> validate_required([:user_id, :raison, :has_genres, :genres])
  end

end
