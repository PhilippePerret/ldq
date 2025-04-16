defmodule LdQWeb.PageHTML do
  use LdQWeb, :html

  embed_templates "page_html/*"

  @doc """
  Renders a page form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true

  def page_form(assigns)

  @doc """
  Retourne l'explication des pages
  """
  def explication(assigns)

end
