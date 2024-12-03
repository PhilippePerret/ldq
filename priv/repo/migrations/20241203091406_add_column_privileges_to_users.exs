defmodule LdQ.Repo.Migrations.AddColumnPrivilegesToUsers do
  use Ecto.Migration

  def change do

    alter table(:users) do
      add :privileges, :integer, default: 0
    end
  end
end
