defmodule LdQWeb.FormController do
  use LdQWeb, :controller

  alias LdQ.Forms

  @doc """
  Tous les formulaires personnalisés passent par ici
  """
  def edit(conn, %{"form" => form} = params) do
    current_user = Map.get(conn.assigns, :current_user, nil)
    params = Map.put(params, "user", current_user)

    phil_path = Path.join([__DIR__,"form_html", "#{form}.phil"])
    html_path = Path.join([__DIR__,"form_html", "#{form}.html.heex"])
    IO.puts "path: #{inspect html_path}"
    IO.inspect(File.exists?(html_path), label: "File.exists?(path)")
    if false == File.exists?(html_path) do
      IO.puts "-> PhilHtml.to_html"
      res = PhilHtml.to_html(phil_path, [dest_name: "#{form}.html.heex", no_header: true, helpers: [LdQ.Site.PageHelpers]])
      IO.inspect(res, label: "Résultat")
      raise "pour voir après la fabrication"
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
      action:     nil
    }
  end

  def get_data_by_form(unknown, params) do
    raise "Le formulaire #{inspect unknown} est inconnu"
  end
end
