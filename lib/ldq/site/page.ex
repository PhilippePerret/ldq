defmodule LdQ.Site.Page do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "pages" do
    field :status, :integer
    field :template, :string
    field :slug, :string
    field :publised_at, :naive_datetime
    field :next_id, :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:slug, :template, :status, :publised_at])
    |> validate_required([:slug, :template, :status])
  end
end
