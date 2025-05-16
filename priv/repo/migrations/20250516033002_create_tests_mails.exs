defmodule LdQ.Repo.Migrations.CreateTestsMails do
  use Ecto.Migration

  def change do
    create table(:tests_mails, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :to, :string
      add :from, :string
      add :subject, :string
      add :body, :text
      add :attachment, :string
      add :mail_id, :string

      timestamps(type: :utc_datetime)
    end
  end
end
