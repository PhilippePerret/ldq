defmodule LdQWeb.AdminController do
  use LdQWeb, :controller

  @doc """
  Page d'accueil de l'administration du site
  """
  def home(conn, _params) do
    render(conn, :home)
  end

end