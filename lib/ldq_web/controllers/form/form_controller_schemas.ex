
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

defmodule LdQ.SubmittedBook do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "submitted_books" do
    field :title, :string
    field :subtitle, :string
    field :isbn, :string
    field :resume, :string
    field :main_genre, :string
    field :sub_genre, :string
    field :user_id, :binary
    field :user_mail, :string
    field :main_author_email, :string
    field :transmit_book, :boolean
    field :url_command, :string
  end

  @doc false
  def changeset(submittedbook, attrs) do
    submittedbook
    |> cast(attrs, [:title, :subtitle, :isbn, :resume, :main_genre, :sub_genre, :user_id, :user_mail, :main_author_mail, :transmit_book, :url_command])
    |> validate_required([:title, :subtitle, :isbn, :resume, :main_genre, :sub_genre, :user_id, :user_mail, :main_author_mail, :transmit_book, :url_command])
  end

end