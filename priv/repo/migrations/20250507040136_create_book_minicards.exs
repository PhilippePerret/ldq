defmodule LdQ.Repo.Migrations.CreateBookMinicards do
  use Ecto.Migration

  def change do
    create table(:book_minicards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :pitch, :text
      add :author_id, references(:authors, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:book_minicards, [:author_id])
  end
end
