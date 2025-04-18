defmodule LdQWeb.FormController do
  use LdQWeb, :controller


  @doc """
  Tous les formulaires personnalisés passent par ici
  """
  def edit(conn, params) do
    current_user = Map.get(conn.assigns, :current_user, nil)

    render(conn, "#{params["form"]}.html", %{
      current_user: current_user
    })
  end

end