defmodule LdQ.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      # Identifiant humain de la notification
      add :notif_dim, :string
      add :procedure_id, references(:procedures, on_delete: :delete_all, type: :binary_id)
      add :data, :map
      add :title, :string
      add :body, :text
      # Pour adresser la notification à un groupe d'utilisateur
      add :group_target, :string # par exemple "admins", "readers", "members", "all"
      # Pour adresser la notification à un utilisateur en particulier
      add :target_type, :string # par exemple "book", "user"
      add :target_id, :binary
      # Mis à True si une action est requise
      add :action_required, :boolean

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:notif_dim])

  end
end
