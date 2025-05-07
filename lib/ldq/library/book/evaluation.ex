defmodule LdQ.Library.Book.Evaluation do
  use Ecto.Schema
  import Ecto.Changeset

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
    field :book_minicard, :binary_id
    field :parrain, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(evaluation, attrs) do
    evaluation
    |> cast(attrs, [:transmitted, :current_phase, :submitted_at, :evaluated_at, :label_grade, :rating, :readers_rating])
    |> validate_required([:transmitted, :current_phase, :submitted_at, :evaluated_at, :label_grade, :rating, :readers_rating])
  end
end
