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

  def regles_objectives(conn, _params) do
    render(conn, :regles_objectives)
  end

  def actu(conn, _params) do
    cuser = conn.assigns[:current_user]
    cond do
    cuser == nil ->
      authentify_and_getback(conn, ~p"/comite/actu")
    User.membre?(cuser) ->
      render(conn, :actu)
    true ->
        render(conn, :acces_interdit)
    end
  end

  def authentify_and_getback(conn, backroute) do
    msg = dgettext("request", "Please log in before accessing this section.")
    conn 
    |> put_flash(:info, msg)
    |> put_session(:backroute, backroute)
    |> redirect(to: ~p"/users/log_in")
  end

end
