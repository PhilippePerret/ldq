defmodule LdQ.Repo.Migrations.CreateProceduresObjects do
  use Ecto.Migration

  def change do
    create table(:procedures_objects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :object_id, :binary
      add :object_type, :string
      add :proc_dim, :string
      add :procedure_id, references(:procedures, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:procedures_objects, [:procedure_id])
  end
end
