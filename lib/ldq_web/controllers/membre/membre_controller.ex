defmodule LdQWeb.MembreController do
  use LdQWeb, :controller

  alias LdQ.Comptes

  def home(conn, %{"membre_id" => membre_id } = _params) do
    membre = Comptes.get_user_as_membre!(membre_id)
    render(conn, :home, membre: membre)
  end

end