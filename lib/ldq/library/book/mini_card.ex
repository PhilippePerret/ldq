defmodule LdQ.Library.Book.MiniCard do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "book_minicards" do
    field :title, :string
    field :pitch, :string
    field :author, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mini_card, attrs) do
    mini_card
    |> cast(attrs, [:title, :pitch])
    |> validate_required([:title, :pitch])
  end
end
