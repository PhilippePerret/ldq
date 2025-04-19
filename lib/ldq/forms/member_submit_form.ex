defmodule LdQ.Forms.MemberSubmit do
 
  import Ecto.Changeset

  defstruct [
    user_id:    nil,
    raison:     nil,
    has_genres: false,
    genres:     []
  ]

  @doc false
  def changeset(data, attrs) do
    attrs = attrs
    |> check_liste_genres()

    data
    |> cast(attrs, [:user_id, :raison, :has_genres, :genres])
    |> validate_required([:user_id, :raison])
  end

  def check_liste_genres(attrs) do
    genres = attrs["genres"] || ""
    genres = String.split(genres, ",") |> Enum.map(fn genre -> String.trim(genre) end)
    Map.put(attrs, "genres", genres)
  end
end