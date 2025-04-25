defmodule LdQWeb.InscritHTML do
  use LdQWeb, :html

  embed_templates "inscrit_html/*"

  attr :user_infos, :map, required: true

  def form_user_infos(assigns)
end