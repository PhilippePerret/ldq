defmodule LdQWeb.AproposHTML do
  @moduledoc """
  Ce module contient les pages servies par le module ChantierController

  Les pages se trouvent dans le dossier chantier_html/
  """
	use LdQWeb, :html
	
	embed_templates "apropos_html/*"
end