defmodule LdQ.Comptes.MemberCard do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "member_cards" do
    field :credit, :integer, default: 0
    
    belongs_to :user, LdQ.Comptes.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member_card, attrs) do
    member_card
    |> cast(attrs, [:credit, :user_id])
    |> validate_required([:credit, :user_id])
  end
end
