defmodule Feature.PageTestMethods do
  use LdQWeb.FeatureCase, async: false
  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  @doc """
  Voir le détail dans feature_methods.ex
  """
  # Quand on cherche une balise avec des attributs (mais +attrs+ peut
  # aussi contenir :text qui définit le contenu).
  def la_page_contient(session, balise, attrs) when is_map(attrs) do
    found = Enum.any?(WB.all(session, css(balise)), fn el ->
      resultat  =
        attrs
        |> Enum.reduce(%{ok: true, oks: [], not_oks: []}, fn {attr, value}, res ->
          comp_value = case attr do
            :text -> WE.text(el)
            _ -> WE.attr(el, attr)
          end
          if comp_value == value do
            %{res | oks: res.oks ++ [{attr, value}]}
          else
            Map.merge(res, %{
              ok: false, not_oks: res.not_oks ++ [{attr, value}]
            })
          end
        end)
      if resultat.ok == false do
        IO.puts [
          IO.ANSI.red(),
          """
          \n# Mauvais élément : #{WE.attr(el, "outerHTML")}
          ## Contient : #{inspect resultat.oks}
          ## Ne contient pas : #{inspect resultat.not_oks}
          """,
          IO.ANSI.reset()
        ]
      end
      resultat.ok
    end)
    assert(found, "Aucune balise #{balise} trouvée possédant les attributs #{inspect attrs}")
    session
  end
  # Quand on cherche une balise et un texte contenu
  def la_page_contient(session, balise, searched) when is_binary(searched) do
    assert Enum.any?(WB.all(session, css(balise)), fn el -> 
      WE.text(el) =~ searched 
    end)
    session
  end
  def la_page_contient(session, balise, searched) do
    assert Enum.any?(WB.all(session, css(balise)), fn el -> 
      Regex.match?(searched, WE.text(el))
    end)
    session
  end
  def la_page_contient(session, searched) do
    searched = if is_binary(searched) do
      ~r/#{searched}/
    else searched end
    assert Regex.match?(searched, WB.page_source(session))
    session
  end

end