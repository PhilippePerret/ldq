defmodule LdQ.Library.Book.MiniCard do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "book_minicards" do
    field :title, :string
    field :pitch, :string

    belongs_to :author, LdQ.Library.Author

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(mini_card, attrs) do
    mini_card
    |> cast(attrs, [:title, :author_id, :pitch])
    |> validate_required([:title, :author_id, :pitch])
  end
end
