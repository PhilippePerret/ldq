defmodule LdQWeb.FormController do
  use LdQWeb, :controller

  alias LdQ.Forms

  @doc """
  Tous les formulaires personnalisés passent par ici
  """
  def edit(conn, %{"form" => form} = params) do
    current_user = Map.get(conn.assigns, :current_user, nil)
    params = Map.put(params, "user", current_user)

    html_path = Path.join([__DIR__,"form_html", "#{form}.html.heex"])
    if false == File.exists?(html_path) do
      phil_path = Path.join([__DIR__, "_philhtml", "#{form}.phil"])
      res = PhilHtml.to_html(phil_path, [dest_name: "#{form}.html.heex", dest_folder: "../form_html", no_header: true, helpers: [LdQ.Site.PageHelpers]])
    end

    data = get_data_by_form(form, params)

    render(conn, "#{form}.html", %{
      current_user: current_user,
      data: data
    })
  end

  def get_data_by_form("member-submit", params) do
    candidat = Map.get(params, "candidat", %{})
    %{
      user_id:    candidat["user_id"] || params["user"].id,
      raison:     candidat["raison"],
      has_genres: candidat["has_genre"],
      genres:     candidat["genres"],
      action:     candidat["action"]
    }
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
      action:             book["action"]
    }
  end

  def get_data_by_form(unknown, params) do
    raise "Le formulaire #{inspect unknown} est inconnu"
  end
end
