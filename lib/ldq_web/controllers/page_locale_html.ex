defmodule LdQWeb.PageLocaleHTML do
  use LdQWeb, :html

  import Phoenix.HTML.Form

  embed_templates "page_locale_html/*"

  @doc """
  Renders a page_locale form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :params, :map, required: true
  attr :action, :string, required: true

  def page_locale_form(assigns)

  def html, do: Phoenix.HTML.Form
end
