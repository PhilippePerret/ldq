defmodule LdQ.Library.UserBook do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_books" do
    field :note, :integer # la note attribuée par le membre lecteur du livre
    belongs_to :user, LdQ.Comptes.User
    belongs_to :book, LdQ.Library.Book

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_book, attrs) do
    user_book
    |> cast(attrs, [:note, :user_id, :book_id])
    |> validate_required([:user_id, :book_id])
  end
end
