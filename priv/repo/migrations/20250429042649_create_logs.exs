defmodule LdQ.Repo.Migrations.CreateLogs do
  use Ecto.Migration

  def change do
    create table(:logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :text, :text
      add :owner_type, :string
      add :owner_id, :binary
      add :public, :boolean, default: true, null: true
      add :created_by, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:logs, [:created_by])
    create index(:logs, [:inserted_at])
  end
end
