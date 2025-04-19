defmodule LdQ.Repo.Migrations.CreateAbsProcs do
  use Ecto.Migration

  def change do
    create table(:abs_procs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :owner_type, :string
      add :short_name, :string
      add :steps, {:array, :string}
      add :short_description, :text
      add :description, :text

      timestamps(type: :utc_datetime)
    end
  end
end
