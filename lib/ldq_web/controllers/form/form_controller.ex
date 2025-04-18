defmodule LdQWeb.FormController do
  use LdQWeb, :controller

  def edit(conn, params) do
    render(conn, :edit, layout: {LdQWeb.Layouts, :plain_page},)
  end

  # def edit(conn, params) do
  #   current_user = Map.get(conn.assigns, :current_user, nil)

  #   # conn = conn 
  #   # |> put_flash(:info, "Chargé à supprimer")

  #   render(conn, "#{params["form"]}.html", %{
  #     current_user: current_user
  #   })
  # end

end