defmodule LdQWeb.AproposHTML do
  @moduledoc """
  Ce module contient les pages servies par le module ChantierController

  Les pages se trouvent dans le dossier chantier_html/
  """
	use LdQWeb, :html
	
	embed_templates "apropos_html/*"

  def retour_manifeste(assigns) do 
    ~H"""
    <center class="mt-20"><a href="/apropos/manifeste{@anchor}">Retour au manifeste</a></center>
    """
  end

  def asterisque_sup(assigns) do
    ~H"<sup>*</sup>"
  end

end