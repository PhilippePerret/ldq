defmodule LdQ.Repo.Migrations.CreateTriggers do
  use Ecto.Migration

  def change do
    create table(:triggers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string
      add :data, :text
      add :uniq_scope, :string
      add :trigger_at, :naive_datetime
      add :priority, :integer
      add :marked_by, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:triggers, [:uniq_scope])
    create index(:triggers, [:marked_by])
  end
end
