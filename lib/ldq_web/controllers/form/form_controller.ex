
defmodule Candidat do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "candidats" do
    field :user_id, :binary
    field :raison, :string
    field :has_genres, :boolean
    field :genres, {:array, :string}
  end

  @doc false
  def changeset(candidat, attrs) do
    candidat 
    |> cast(attrs, [:user_id, :raison, :has_genres, :genres])
    |> validate_required([:user_id, :raison, :has_genres, :genres])
  end

end

defmodule LdQWeb.FormController do
  use LdQWeb, :controller

  # alias LdQ.Forms

  @doc """
  Tous les formulaires personnalisés passent par ici
  """
  def edit(conn, %{"form" => form} = params) do
    current_user = Map.get(conn.assigns, :current_user, nil)
    params = Map.put(params, "user", current_user)

    html_path = Path.join([__DIR__,"form_html", "#{form}.html.heex"])
    if false == File.exists?(html_path) do
      phil_path = Path.join([__DIR__, "_philhtml", "#{form}.phil"])
      PhilHtml.to_html(phil_path, [dest_name: "#{form}.html.heex", dest_folder: "../form_html", no_header: true, helpers: [LdQ.Site.PageHelpers]])
    end

    changeset = get_data_by_form(form, params)

    render(conn, "#{form}.html", %{
      current_user: current_user,
      changeset: changeset
    })
  end

  def get_data_by_form("member-submit", params) do
    candidat = Map.get(params, "candidat", %{})
    Candidat.changeset(%Candidat{}, %{
      user_id:    candidat["user_id"] || params["user"].id,
      raison:     candidat["raison"],
      has_genres: candidat["has_genre"],
      genres:     candidat["genres"],
    })
  end

  def get_data_by_form("book-submit", params) do
    book = Map.get(params, "book", %{})
    %{
      title:              book["title"],
      subtitle:           book["subtitle"],
      isbn:               book["isbn"],
      resume:             book["resume"],
      main_genre:         book["main_genre"],
      sub_genre:          book["sub_genre"],
      user_id:            book["user_id"]||(book["user"] && book["user"].id),
      user_mail:          book["user_mail"]||(book["user"] && book["user"].email),
      main_author_email:  book["main_author_email"],
      transmit_book:      book["transmit_book"]||true,
      command_url:        book["command_url"],
    }
  end

  def get_data_by_form(unknown, _params) do
    raise "Le formulaire #{inspect unknown} est inconnu"
  end
end

