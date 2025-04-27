defmodule LdQWeb.AdminController do
  use LdQWeb, :controller

  # import LdQ.ProcedureMethods, only: [get_procedure: 1]

  @doc """
  Page d'accueil de l'administration du site
  """
  def home(conn, _params) do
    check_phil_page("home")
    render(conn, :home)
  end

  @doc """
  Fonction principale qui affiche une procédure et permet de la gérer

  @OBSOLETE Voir le controler ProcedureController maintenant
  """
  def procedure(_conn, %{"proc_id" => _proc_id} = _params) do
    raise "Il faut utiliser maintenant ProcedureController.run/3"
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