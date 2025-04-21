defmodule LdQ.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "notifications" do
    field :notif_dim, :string
    field :data, :map
    field :title, :string
    field :body, :string
    field :group_target, :string # p.e. "admins", "readers", "members"
    field :target_type, :string # p.e. "user", "book"
    field :target_id, :binary
    field :action_required, :boolean

    belongs_to :procedure, LdQ.Procedure

    timestamps(type: :utc_datetime)
  end


  def changeset(%__MODULE__{} = notification, attrs) do
    notification
    |> cast(attrs, [:notif_dim, :procedure_id, :data, :title, :body, :group_target, :target_type, :target_id, :action_required])
    |> validate_required([:notif_dim, :procedure_id, :data, :body, :action_required])
  end
end