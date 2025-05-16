defmodule LdQ.Library.Book do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "books" do
    field :title, :string
    field :pitch, :string
    # --- Spécifications ---
    field :label, :boolean, default: false
    field :isbn, :string
    field :published_at, :date
    field :subtitle, :string
    field :label_year, :integer
    field :url_command, :string
    field :pre_version_id, :binary_id
    # --- Evaluation ---
    field :transmitted, :boolean, default: false
    field :current_phase, :integer
    field :submitted_at, :naive_datetime
    field :evaluated_at, :naive_datetime
    field :label_grade, :integer
    field :rating, :integer
    field :readers_rating, :integer
    # --- Appartenance ---
    belongs_to :parrain, LdQ.Comptes.User
    belongs_to :publisher, Lib.Publisher
    belongs_to :author, LdQ.Library.Author

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(book, attrs) do
    book
    |> cast(attrs, [
      :author_id, 
      :current_phase, 
      :evaluated_at, 
      :isbn, 
      :label, 
      :label_grade, 
      :label_year, 
      :parrain_id, 
      :pitch, 
      :pre_version_id,
      :published_at, 
      :publisher_id, 
      :rating, 
      :readers_rating,
      :submitted_at, 
      :subtitle, 
      :title, 
      :transmitted, 
      :url_command
      ])
    |> validate_required([:title, :author_id, :pitch])
  end
end
