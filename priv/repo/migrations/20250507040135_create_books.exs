defmodule LdQ.Repo.Migrations.CreateBooks do
  @doc """
  La grand table contenant toutes les informations sur le livre
  """
  use Ecto.Migration

  def change do
    create table(:books, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string
      add :pitch, :text
      # --- Specs ---
      add :isbn, :string
      add :published_at, :date
      add :subtitle, :string
      add :label, :boolean, default: false, null: false
      add :label_year, :integer
      add :url_command, :string
      # --- Évaluation ---
      add :transmitted, :boolean, default: false, null: false
      add :current_phase, :integer
      add :submitted_at, :naive_datetime
      add :evaluated_at, :naive_datetime
      add :label_grade, :integer
      add :rating, :integer
      add :readers_rating, :integer

      add :parrain_id, references(:users, on_delete: :nothing, type: :binary_id)
      add :publisher_id, references(:publishers, on_delete: :delete_all, type: :binary_id)
      add :pre_version_id, references(:books, on_delete: :nothing, type: :binary_id)
      add :author_id, references(:authors, on_delete: :delete_all, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:books, [:author_id])
    create index(:books, [:publisher_id])
    create index(:books, [:parrain_id])

  end
end
