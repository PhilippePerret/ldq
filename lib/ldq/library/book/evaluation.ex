defmodule LdQ.Library.Book.Evaluation do
  use Ecto.Schema
  import Ecto.Changeset
  alias LdQ.Library.Book

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "book_evaluations" do
    field :transmitted, :boolean, default: false
    field :current_phase, :integer
    field :submitted_at, :naive_datetime
    field :evaluated_at, :naive_datetime
    field :label_grade, :integer
    field :rating, :integer
    field :readers_rating, :integer
    field :parrain, :binary_id

    belongs_to :book_minicard, Book.MiniCard

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(evaluation, attrs) do
    evaluation
    |> cast(attrs, [:book_minicard_id, :transmitted, :current_phase, :submitted_at, :evaluated_at, :label_grade, :rating, :readers_rating])
    |> validate_required([:book_minicard_id, :current_phase, :submitted_at])
  end
end
