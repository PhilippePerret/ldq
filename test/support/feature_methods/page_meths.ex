defmodule Feature.PageTestMethods do
  use LdQWeb.FeatureCase, async: false
  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  @doc """
  Voir le détail dans feature_methods.ex
  """

  # Quand on cherche un bouton (ça peut être button ou a.btn)
  def la_page_contient(session, "button", searched, attrs) when is_binary(searched) do
    la_page_contient(session, "button", ~r/#{Regex.escape(searched)}/, attrs)
  end
  def la_page_contient(session, "button", searched, attrs) when is_struct(searched, Regex) do
    ok = Enum.any?(WB.all(session, css("button")), fn el -> 
      ok_text = WE.text(el) =~ searched 
      ok_attrs = attrs 
        |> Enum.reduce(%{ok: true, errors: []}, fn {attr, value}, res ->
          if WE.attribute(attr) == value do 
            res
          else
            Map.merge(res, %{ok: false, errors: res.errors ++ ["Prop #{attr} devrait valoir #{inspect value}, il vaut #{WE.attribute(attr)}."]})
          end
        end)
      ok_text and ok_attrs.ok
    end)
    ok = ok || Enum.any?(WB.all(session, css("a.btn")), fn el -> 
      ok_text = WE.text(el) =~ searched 
    end)
    assert(ok)
    session
  end
  # Quand on cherche une balise et un texte contenu
  def la_page_contient(session, balise, searched) when is_binary(searched) do
    assert Enum.any?(WB.all(session, css(balise)), fn el -> 
      WE.text(el) =~ searched 
    end)
    session
  end

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
  def la_page_contient(session, balise, searched) do
    assert Enum.any?(WB.all(session, css(balise)), fn el -> 
      Regex.match?(searched, WE.text(el))
    end)
    session
  end
  def la_page_contient(session, searched) do
    searched = if is_binary(searched) do
      ~r/#{Regex.escape(searched)}/
    else searched end

    # IO.inspect(WB.page_source(session), label: "\n\n+++ PAGE COMPLÈTE", printable_limit: :infinity)
    assert Regex.match?(searched, WB.page_source(session))
    session
  end

end