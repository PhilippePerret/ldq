defmodule LdQ.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string
      add :template, :string
      add :status, :integer
      add :published_at, :naive_datetime
      add :next_id, references(:pages, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:pages, [:next_id])
  end
end
