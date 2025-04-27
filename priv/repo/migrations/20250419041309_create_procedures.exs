defmodule LdQ.Repo.Migrations.CreateProcedures do
  use Ecto.Migration

  def change do
    create table(:procedures, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :proc_dim, :string
      # Le type du sujet de la procédure, par exemple "book" ou "user"
      add :owner_type, :string
      # L'identifiant du sujet de la procédure
      add :owner_id, :binary
      # L'étape courante
      add :current_step, :string
      # La prochaine étape à accomplir
      add :next_step, :string
      # Les étapes déjà effectuées
      add :steps_done, {:array, :string}
      # Les données quelconques de la procédure
      add :data, :map
      # Pour connaitre celui qui a soumis la procédure
      add :submitter_id, references(:users, on_delete: :delete_all, type: :binary_id)


      timestamps(type: :utc_datetime)
    end

    create index(:procedures, [:proc_dim])
    create index(:procedures, [:submitter_id])

  end
end
