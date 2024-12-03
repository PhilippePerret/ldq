defmodule LdQWeb.ComiteController do
  use LdQWeb, :controller

  alias LdQ.Comptes.User

  def portail(conn, _params) do
    cuser = conn.assigns[:current_user]
    if cuser do
      render(conn, :portail)
    else
      render(conn, :acces_interdit)
    end
  end

  def actu(conn, _params) do
    cuser = conn.assigns[:current_user]
    cond do
    cuser == nil ->
      conn 
      |> put_flash(:info, dgettext("request", "You have to log in."))
      |> assign(:backroute, ~p"/comite/actu")
      |> redirect(to: ~p"/users/log_in")
    User.membre?(cuser) ->
      render(conn, :actu)
    true ->
        render(conn, :acces_interdit)
    end
  end
end