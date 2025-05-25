defmodule LdQ.Repo.Migrations.CreateUsersBooks do
  use Ecto.Migration

  def change do
    create table(:users_books, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :note, :integer
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)
      add :book_id, references(:books, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:users_books, [:user_id])
    create index(:users_books, [:book_id])
  end
end
