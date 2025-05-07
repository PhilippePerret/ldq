defmodule LdQ.Repo.Migrations.CreateAuthors do
  use Ecto.Migration

  def change do
    create table(:authors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :firstname, :string
      add :lastname, :string
      add :pseudo, :string
      add :email, :string
      add :url_perso, :string
      add :birthyear, :integer
      add :address, :text
      add :user_id, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:authors, [:user_id])
  end
end
