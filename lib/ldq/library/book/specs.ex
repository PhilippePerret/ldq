defmodule LdQ.Library.Book.Specs do
  use Ecto.Schema
  import Ecto.Changeset

  alias LdQ.Library.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "book_specs" do
    field :label, :boolean, default: false
    field :isbn, :string
    field :published_at, :naive_datetime
    field :subtitle, :string
    field :label_year, :integer
    field :url_command, :string
    field :publisher, :binary_id
    field :pre_version, :binary_id

    belongs_to :book_minicard, Book.MiniCard

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(specs, attrs) do
    specs
    |> cast(attrs, [:book_minicard_id, :isbn, :published_at, :subtitle, :label, :label_year, :url_command])
    |> validate_required([:book_minicard_id, :isbn, :published_at, :subtitle, :label, :label_year, :url_command])
  end
end
