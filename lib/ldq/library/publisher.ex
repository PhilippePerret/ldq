defmodule LdQ.Library.Publisher do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "publishers" do
    field :name, :string
    field :address, :string
    field :email, :string
    field :phone, :string
    field :pays, :string
    field :num_isbn, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(publisher, attrs) do
    publisher
    |> cast(attrs, [:name, :address, :email, :phone, :pays, :num_isbn])
    |> validate_required([:name, :pays])
  end
end
