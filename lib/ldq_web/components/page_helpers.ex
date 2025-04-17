defmodule LdQ.Site.PageHelpers do
  @moduledoc """
  Ce module est envoyé à PhilHtml pour traiter les pages
  """

  def ldq_label do
    ~s(<span class="label">Lecture de Qualité</span>)
  end

  def tiret do
    ~s(<font face="serif">-</font>)
  end

  def loclink(slug, title, retour \\ nil) do
    back =
      if is_nil(retour) do "" else
        [slug, ancre] = String.split(retour, "#")
        |> IO.inspect(label: "retour")
        ~s(?back=#{slug}&anchor=#{ancre})
      end
    ~s(<a href="/pg/#{slug}#{back}">#{title}</a>)
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