defmodule LdQWeb.AdminController do
  use LdQWeb, :controller

  @doc """
  Page d'accueil de l'administration du site
  """
  def home(conn, _params) do
    check_phil_page("home")
    render(conn, :home)
  end

  def check_phil_page(base) do
    root = Path.join([__DIR__,"admin_html","#{base}"])
    phil = "#{root}.phil"
    dest = "#{root}.html.heex"
    if !File.exists?(dest) do
      PhilHtml.to_html(phil, [
        dest_name: "#{base}.html.heex", 
        no_header: true,
        evaluation: false
        ])
    end
  end

end