defmodule LdQ.Repo.Migrations.CreatePageLocales do
  use Ecto.Migration

  def change do
    create table(:page_locales, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :locale, :string
      add :status, :integer
      add :title, :string
      add :raw_content, :text
      add :content, :text
      add :summary, :text
      add :meta_title, :string
      add :meta_description, :string
      add :image, :string
      add :page_id, references(:pages, on_delete: :nothing, type: :binary_id)
      add :author, references(:users, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:page_locales, [:page_id])
    create index(:page_locales, [:author])
  end
end
