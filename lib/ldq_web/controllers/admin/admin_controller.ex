defmodule LdQWeb.AdminController do
  use LdQWeb, :controller

  import LdQ.ProcedureMethods, only: [get_procedure: 1]

  @doc """
  Page d'accueil de l'administration du site
  """
  def home(conn, _params) do
    check_phil_page("home")
    render(conn, :home)
  end

  @doc """
  Fonction principale qui affiche une procédure et permet de la gérer

  """
  def procedure(conn, %{"proc_id" => proc_id} = params) do
    procedure = 
    get_procedure(proc_id)
    |> Map.put(:params, params)
    
    procedure = 
      if is_nil(params["nstep"]) do procedure else
        Map.put(procedure, :next_step, params["nstep"])
      end
    render(conn, :procedure, procedure: procedure)
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