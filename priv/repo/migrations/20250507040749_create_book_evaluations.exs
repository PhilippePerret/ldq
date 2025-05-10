defmodule LdQ.Repo.Migrations.CreateBookEvaluations do
  use Ecto.Migration

  def change do
    create table(:book_evaluations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :transmitted, :boolean, default: false, null: false
      add :current_phase, :integer
      add :submitted_at, :naive_datetime
      add :evaluated_at, :naive_datetime
      add :label_grade, :integer
      add :rating, :integer
      add :readers_rating, :integer
      add :book_minicard_id, references(:book_minicards, on_delete: :delete_all, type: :binary_id)
      add :parrain_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:book_evaluations, [:book_minicard_id])
    create index(:book_evaluations, [:parrain_id])
  end
end
