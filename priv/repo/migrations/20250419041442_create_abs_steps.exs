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

      timestamps(type: :utc_datetime)
    end
  end
end
