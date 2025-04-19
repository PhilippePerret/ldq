defmodule LdQ.Repo.Migrations.CreateAbsSteps do
  use Ecto.Migration

  def change do
    create table(:abs_steps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :short_name, :string
      add :fonction, :string
      add :data, :map
      add :short_description, :text
      add :description, :text
      add :last, :boolean, default: false
      add :abs_proc_id, references(:abs_procs, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:abs_steps, [:short_name])
    create index(:abs_steps, [:abs_proc_id])

  end
end
