defmodule LdQWeb.PageLocaleHTML do
  use LdQWeb, :html

  embed_templates "page_locale_html/*"

  @doc """
  Renders a page_locale form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :params, :map, required: true
  attr :action, :string, required: true

  def page_locale_form(assigns)

  def html, do: Phoenix.HTML.Form

  attr :title, :string, default: "Actualiser le contenu d'après le fichier"
  attr :page_locale, :map, required: true

  def lien_update_content(assigns) do
    ~H"""
    <a href={"/page_locales/#{@page_locale.id}/update-content"}><%= @title %></a>
    """

  end
end
