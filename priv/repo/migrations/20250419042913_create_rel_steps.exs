defmodule LdQ.Repo.Migrations.CreateRelSteps do
  use Ecto.Migration

  def change do
    create table(:rel_steps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :integer
      add :resultat, :map
      add :abs_step_id, references(:abs_steps, on_delete: :delete_all, type: :binary_id)
      add :rel_proc_id, references(:rel_procs, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:rel_steps, [:abs_step_id])
    create index(:rel_steps, [:rel_proc_id])
  end
end
