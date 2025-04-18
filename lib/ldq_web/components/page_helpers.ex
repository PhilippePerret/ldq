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

  def formlink(title, slug, retour \\ nil) do
    build_link("form", slug, title, retour)
  end

  def pagelink(title, slug, retour \\ nil) do
    build_link("pg", slug, title, retour)
  end

  @doc """
  Fonction générique pour créer un lien vers une partie

  @param {String} prefix Pour le moment "pg" ou "form"
  @param {String} slug de la page (identifiant générique, indépendant de la langue)
  @param {String} title Le titre affiché
  @param {String} retour Pour retourner à la page précédente : "<slug>[#<anchor>]"
  """
  def build_link(prefix, slug, title, retour \\ nil) do
    back =
      cond do
        is_nil(retour) -> ""
        Regex.match?(~r/#/, retour) ->
          [slug, ancre] = String.split(retour, "#")
          ~s(?back=#{slug}&anchor=#{ancre})
        true -> 
          "?back=#{retour}"
      end
    ~s(<a href="/#{prefix}/#{slug}#{back}">#{title}</a>)
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


  @doc """
  Formulaire pour soumettre sa candidature au comité de lecture du label.
  """
  def form_comitee_reader(params) do
    current_user = Map.get(params, :current_user, nil)
    """
    <form>
      [Formulaire pour soumettre sa candidature par #{inspect params.current_user}]
    </form>
    """
  end


end