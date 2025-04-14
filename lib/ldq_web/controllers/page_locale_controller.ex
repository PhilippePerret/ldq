defmodule LdQWeb.PageLocaleController do
  use LdQWeb, :controller

  alias LdQ.Site
  alias LdQ.Site.PageLocale

  def index(conn, _params) do
    page_locales = Site.list_page_locales()
    render(conn, :index, page_locales: page_locales)
  end

  defp common_params do
    %{}
    |> Map.put(:pages, Site.list_pages() |> Enum.map(&{&1.slug, &1.id}))
  end

  def new(conn, _params) do
    changeset = Site.change_page_locale(%PageLocale{})
    render(conn, :new, changeset: changeset, params: common_params())
  end

  def create(conn, %{"page_locale" => page_locale_params}) do
    case Site.create_page_locale(page_locale_params) do
      {:ok, page_locale} ->
        conn
        |> put_flash(:info, "Page locale created successfully.")
        |> redirect(to: ~p"/page_locales/#{page_locale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, params: common_params())
    end
  end

  def show(conn, %{"id" => id}) do
    page_locale = Site.get_page_locale!(id)
    render(conn, :show, page_locale: page_locale)
  end

  def edit(conn, %{"id" => id}) do
    page_locale = Site.get_page_locale!(id)
    changeset = Site.change_page_locale(page_locale)
    render(conn, :edit, page_locale: page_locale, changeset: changeset, params: common_params())
  end

  def update(conn, %{"id" => id, "page_locale" => page_locale_params}) do
    page_locale = Site.get_page_locale!(id)

    case Site.update_page_locale(page_locale, page_locale_params) do
      {:ok, page_locale} ->
        conn
        |> put_flash(:info, "Page locale updated successfully.")
        |> redirect(to: ~p"/page_locales/#{page_locale}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, page_locale: page_locale, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    page_locale = Site.get_page_locale!(id)
    {:ok, _page_locale} = Site.delete_page_locale(page_locale)

    conn
    |> put_flash(:info, "Page locale deleted successfully.")
    |> redirect(to: ~p"/page_locales")
  end
end
