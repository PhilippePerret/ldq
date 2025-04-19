defmodule LdQ.Repo.Migrations.CreateRelProcs do
  use Ecto.Migration

  def change do
    create table(:rel_procs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :owner_id, :binary
      add :status, :integer
      add :abs_proc_id, references(:abs_procs, on_delete: :delete_all, type: :binary_id)
      add :followed_by, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:rel_procs, [:abs_proc_id])
    create index(:rel_procs, [:followed_by])
  end
end
