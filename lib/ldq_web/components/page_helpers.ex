defmodule LdQ.Site.PageHelpers do
  @moduledoc """
  Ce module est envoyé à PhilHtml pour traiter les pages
  """

  def ldq_label do
    "LABEL LECTURE DE QUALITÉ"
  end

  def loclink(slug, title) do
    "<a>Je dois faire un lien vers #{slug} de titre #{title}</a>"
  end

  def lien_faire_connaitre(type) do
    case type do
      "si_lecteur" ->
        "{lien faire connaitre pour lecteur}"
      "si_auteur" ->
        "{lien faire connaitre pour auteur}"
      "tout_cela" ->
        "{lien faire connaitre pour lecteur-auteur}"
      _ ->
        "{autre lien faire connaitre pour #{type}}"
    end
  end

end