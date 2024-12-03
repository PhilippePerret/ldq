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

  def submission_book_form(titre) when is_binary(titre) do
    submission_book_form(%{titre: titre})
  end

  def submission_book_form(%{} = assigns) do
    ~H"""
    <a href={~p"/livres/soumettre"}><%= @titre %></a>
    """
  end
 
  def submission_book_form() do 
    submission_book_form(%{titre: "formulaire de soumission d’un livre"})
  end

end