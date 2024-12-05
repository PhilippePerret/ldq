defmodule LdQWeb.AproposHTML do
  @moduledoc """
  Ce module contient les pages servies par le module ChantierController

  Les pages se trouvent dans le dossier chantier_html/
  """
	use LdQWeb, :html
	
	embed_templates "apropos_html/*"


  @doc """
  Pour "Local Link", c'est-à-dire un lien local.

  Retourne un lien vers un fichier "à propos" (et seulement vers un fichier de ce dossier)

  Permet d'écrire dans le code : <.loclink titre="<titre>" fname="<nom fichier>"

  Le lien est appelée en fournissant une ancre qui permettra de revenir au même 
  endroit du texte. Il faut donc, au-dessus de cette balise <.loclink, ajouter un 
  <a name="<fname|anchor>"></a>.
  Par défaut, cette ancre est le nom du fichier, mais si le même fichier était appelé
  à différents endroits du texte, il faudrait mettre des ancres différentes et les
  préciser à l'aide du paramètre 'aname' (pour "anchor name", "nom de l'ancre").

  """
  attr :fname, :string, required: true
  attr :titre, :string, default: nil
  attr :aname, :string, default: nil
  def loclink(assigns) do
    ~H"""
     <a href={~p"/apropos/#{@fname}?anchor=#{@aname||@fname}"}><%= @titre || @fname %></a>
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