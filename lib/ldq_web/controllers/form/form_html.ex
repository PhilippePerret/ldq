defmodule LdQWeb.FormHTML do
  use LdQWeb, :html

  embed_templates "form_html/*"


  attr :changeset, Ecto.Changeset, required: true
  def form_member_submit(assigns)
  
  attr :changeset, Ecto.Changeset, required: true
  def form_book_submit(assigns)

end