defmodule LdQ.Repo.Migrations.CreatePublishers do
  use Ecto.Migration

  def change do
    create table(:publishers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :address, :text
      add :email, :string
      add :phone, :string
      add :pays, :string
      add :num_isbn, :string

      timestamps(type: :utc_datetime)
    end
  end
end
