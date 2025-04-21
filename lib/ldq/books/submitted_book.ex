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
    |> cast(attrs, [:title, :subtitle, :isbn, :resume, :main_genre, :sub_genre, :user_id, :user_mail, :main_author_email, :transmit_book, :url_command])
    |> validate_required([:title, :subtitle, :isbn, :resume, :main_genre, :sub_genre, :user_id, :user_mail, :main_author_email, :transmit_book, :url_command])
  end

end