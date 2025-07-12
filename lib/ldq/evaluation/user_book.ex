defmodule LdQ.Evaluation.UserBook do
  @moduledoc """
  Table d'association entre un livre et un lecteur (spécialement
  membre du comité de lecture, dans un collège)

  TODO
    IL FAUT ABSOLUMENT ASSOCIER LA FICHE À UN COLLÈGE, SINON, ON
    NE SAURA PLUS À QUELLE ÉVALUATION CORRESPOND LA FICHE
    - REMONTER DE DEUX MIGRATIONS
    - AJOUTER LA PROPRIÉTÉ COLLEGE
    - RESETTER PARTOUT (MODE TEST AUSSI)
    - RELANCER TOUS LES TESTS POUR REFAIRE LES PHOTOGRAPHIES
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias LdQ.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users_books" do
    field :note, :integer, default: nil # la note attribuée par le membre lecteur du livre
    # field :college, :integer # <============ TODO TRAITER (MIGRATION ETC.)
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


  @doc """
  Permet d'associer un user (membre du comité) à un livre, en
  appliquant les paramètres +attrs+ (qui, pour le moment, ne
  peut définir que la note de 0 à 40)

  @return L'association créée
  """
  def assoc_user_and_book(user, book, attrs \\ %{}) do
    # On met une barrière si l'user n'est pas un membre
    LdQ.Comptes.User.membre?(user) || raise("Impossible d'associer un livre à quelqu'un qui n'appartient pas au comité de lecture…")
    attrs = Map.merge(attrs, %{user_id: user.id, book_id: book.id})

    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Actualise l'association entre le membre et le livre
  """
  def update!(user, book, attrs) do
    Repo.get_by!(__MODULE__, [user_id: user.id, book_id: book.id])
    |> changeset(attrs)
    |> Repo.update!()
  end

end
