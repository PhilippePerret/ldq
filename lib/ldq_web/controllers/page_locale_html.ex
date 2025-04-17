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
    <a href={"/page_locales/#{@page_locale.id}/update-content"} style="margin-right:2em;"><%= @title %></a>
    """
  end

  attr :page_locale, :map, required: true

  @doc """
  Génère une lien vers la page publique
  """
  def lien_display(assigns) do
    assigns = assigns 
    |> assign(:slug, assigns.page_locale.page.slug)
    |> assign(:lang, assigns.page_locale.locale)

    ~H"""
    <a href={~p"/pg/#{@slug}?lang=#{@lang}"} target="_blank">⇱ Voir sur le site</a>
    """
  end
end
