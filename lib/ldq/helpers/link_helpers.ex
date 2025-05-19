defmodule LdQ.LinkHelpers do

  alias LdQ.Constantes
  # import LdQ.Site.PageHelpers

  def full_url(rel_url) do
    [Constantes.get(:app_url), rel_url] |> Enum.join("/")
  end

  @doc """
  Return l'URL de la page de début au sein du comité de lecture.
  Elle a été inaugurée pour y diriger le nouveau membre du comité.

  @param {Boolean} full Si True, on retourne une URL complète. Sinon, elle sera relative.
  """
  def page_debut_comite_lecture(_title, full \\ false) do
    url = "pg/debut-comite-lecture"
    if full, do: full_url(url), else: url
  end

end