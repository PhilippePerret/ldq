defmodule LdQWeb.ComiteController do
  use LdQWeb, :controller

  def portail(conn, %{"current_user" => _user} = _params) do
    render(conn, :portail)
  end
  def portail(conn, _params) do
    render(conn, :acces_interdit)
  end
end