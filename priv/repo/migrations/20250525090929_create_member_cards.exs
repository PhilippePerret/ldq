defmodule LdQ.Repo.Migrations.CreateMemberCards do
  use Ecto.Migration

  def change do
    create table(:member_cards, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :credit, :integer, default: 0
      add :user_id, references(:users, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:member_cards, [:user_id])
  end
end
