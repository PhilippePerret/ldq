defmodule LdQ.Proc.AbsStep do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "abs_steps" do
    field :data, :map
    field :name, :string
    field :description, :string
    field :short_name, :string
    field :fonction, :string
    field :short_description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(abs_step, attrs) do
    abs_step
    |> cast(attrs, [:name, :short_name, :fonction, :data, :short_description, :description])
    |> validate_required([:name, :short_name, :fonction, :short_description, :description])
  end
end
