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
      add :book_minicard_id, references(:book_minicards, on_delete: :delete_all, type: :binary_id)
      add :publisher_id, references(:publishers, on_delete: :delete_all, type: :binary_id)
      add :pre_version_id, references(:book_minicards, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:book_specs, [:book_minicard_id])
    create index(:book_specs, [:publisher_id])
    create index(:book_specs, [:pre_version_id])
  end
end
