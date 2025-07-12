defmodule LdQ.Comptes.MemberCard do
  @moduledoc """
  Carte de membre d'un membre du comité de lecture.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias LdQ.Repo

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

  # ----------------------------------------------------------- #

  def create_for(user) do
    %__MODULE__{}
    |> changeset(%{user_id: user.id, credit: 0})
    |> Repo.insert!()
  end

  def get!(id) do
    Repo.get!(__MODULE__, id)
  end

  def update(member_card, attrs) when is_struct(member_card, __MODULE__) do
    member_card
    |> changeset(attrs)
    |> Repo.update!()
  end

  def update(id, attrs) when is_binary(id) do
    member_card = get!(id)
    update(member_card, attrs)
  end


end
