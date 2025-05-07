defmodule LdQ.Repo.Migrations.CreateBookSpecs do
  use Ecto.Migration

  def change do
    create table(:book_specs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :isbn, :string
      add :published_at, :naive_datetime
      add :subtitle, :string
      add :label, :boolean, default: false, null: false
      add :label_year, :integer
      add :url_command, :string
      add :book_minicard, references(:book_minicards, on_delete: :nothing, type: :binary_id)
      add :publisher, references(:publishers, on_delete: :nothing, type: :binary_id)
      add :pre_version, references(:book_minicards, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:book_specs, [:book_minicard])
    create index(:book_specs, [:publisher])
    create index(:book_specs, [:pre_version])
  end
end
