defmodule LdQWeb.InscritController do
  use LdQWeb, :controller

  alias LdQ.Comptes
  
  # import Phil.File, only: [file_mtime: 1]

  @doc """
  Fonction principale qui affiche la page volue
  """
  def display_page(conn, %{"page" => page} = _params) do
    LdQ.PhilHtml.check_feminize_file(page, __DIR__)
    user = conn.assigns.current_user
    render(conn, "#{page}-#{user.sexe}.html", user: user)
  end

  # Pour afficher un autre profil que le sien
  def show(conn, %{"user_id" => user_id} = _params) do
    user = Comptes.get_user!(user_id)
    render(conn, "show.html", user: user)
  end

end