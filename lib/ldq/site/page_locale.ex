defmodule LdQ.Site.PageLocale do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "page_locales" do
    field :status, :integer
    field :title, :string
    field :image, :string
    field :locale, :string
    field :raw_content, :string
    field :content, :string
    field :summary, :string
    field :meta_title, :string
    field :meta_description, :string
    field :author, :binary_id

    belongs_to :page, LdQ.Site.Page

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page_locale, attrs) do
    attrs = attrs
    |> compose_content()

    page_locale
    |> cast(attrs, [:locale, :page_id, :status, :title, :raw_content, :content, :summary, :meta_title, :meta_description, :image])
    |> validate_required([:page_id, :locale, :status, :title, :raw_content, :content, :summary])
  end

  # Fonction qui prend le raw content de la page locale et crée le 
  # code provisoire.
  defp compose_content(attrs) do
    formatted_content = PhilHtml.to_heex(Map.get(attrs, "raw_content", "[Page sans contenu]"), [no_header: true])
    Map.put(attrs, "content", formatted_content)
  end
end
