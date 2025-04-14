defmodule LdQWeb.PageController do
  use LdQWeb, :controller

  alias LdQ.Site
  alias LdQ.Site.Page

  def index(conn, _params) do
    pages = Site.list_pages()
    render(conn, :index, pages: pages)
  end

  def new(conn, _params) do
    changeset = Site.change_page(%Page{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"page" => page_params}) do
    case Site.create_page(page_params) do
      {:ok, page} ->
        conn
        |> put_flash(:info, "Page created successfully.")
        |> redirect(to: ~p"/pages/#{page}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    page = Site.get_page!(id)
    render(conn, :show, page: page)
  end

  def edit(conn, %{"id" => id}) do
    page = Site.get_page!(id)
    changeset = Site.change_page(page)
    render(conn, :edit, page: page, changeset: changeset)
  end

  def update(conn, %{"id" => id, "page" => page_params}) do
    page = Site.get_page!(id)

    case Site.update_page(page, page_params) do
      {:ok, page} ->
        conn
        |> put_flash(:info, "Page updated successfully.")
        |> redirect(to: ~p"/pages/#{page}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, page: page, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    page = Site.get_page!(id)
    {:ok, _page} = Site.delete_page(page)

    conn
    |> put_flash(:info, "Page deleted successfully.")
    |> redirect(to: ~p"/pages")
  end
end
