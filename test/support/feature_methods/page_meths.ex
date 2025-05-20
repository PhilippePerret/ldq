defmodule Feature.PageTestMethods do
  use LdQWeb.FeatureCase, async: false
  alias Wallaby.Browser,  as: WB
  # alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  import Feature.SessionMethods


  @doc """
  Méthode permettant de savoir si on est sur la page d'identification
  ou non.

  @return True si on est sur la page d'identification, False dans le
  cas contraire.
  """
  def on_login_page?(visiteur) do
    session = session_from(visiteur)
    Enum.any?(WB.all(session, css("h2")), fn el -> 
      WE.text(el) =~ "Identification"
    end)
  end

  @doc """
  Pour ramener la page de la session devant.
  """
  def focus(sujet) do
    session = session_from(sujet)
    WB.focus_window(session, sujet.window_handle)
    sujet
  end

  @doc """
  Voir le détail dans feature_methods.ex
  """
  # Quand on cherche un bouton (ça peut être button ou a.btn)
  def la_page_contient(session, "button", searched, attrs) when is_binary(searched) do
    la_page_contient(session, "button", ~r/#{Regex.escape(searched)}/, attrs)
  end
  def la_page_contient(sujet, "button", searched, attrs) when is_struct(searched, Regex) do
    session = session_from(sujet)
    ok = Enum.any?(WB.all(session, css("button")), fn el -> 
      ok_text = WE.text(el) =~ searched 
      ok_attrs = attrs 
        |> Enum.reduce(%{ok: true, errors: []}, fn {attr, value}, res ->
          if WE.attr(el, attr) == value do 
            res
          else
            Map.merge(res, %{ok: false, errors: res.errors ++ ["Prop #{attr} devrait valoir #{inspect value}, il vaut #{WE.attr(attr)}."]})
          end
        end)
      ok_text and ok_attrs.ok
    end)
    ok = ok || Enum.any?(WB.all(session, css("a.btn")), fn el -> 
      WE.text(el) =~ searched 
    end)
    assert(ok)
    sujet
  end
  # Quand on cherche une balise et un texte contenu
  def la_page_contient(sujet, balise, searched) when is_binary(balise) and is_binary(searched) do
    session = session_from(sujet)
    assert Enum.any?(WB.all(session, css(balise)), fn el -> 
      WE.text(el) =~ searched 
    end)
    sujet
  end
  # Quand on recherche une liste de string/balise/regex
  def la_page_contient(sujet, liste, _params) when is_list(liste) do
    liste |> Enum.each(fn searched -> 
      # la_page_contient(sujet, searched, params)
      # Pour l'instant on ne peut que faire ça, sinon c'est une 
      # balise qui est recherchée TODO Reprendre toutes les 
      # conditions possible est faire les bons guards
      la_page_contient(sujet, searched)
    end)
    sujet
  end
  # Quand on cherche une balise avec des attributs (mais +attrs+ peut
  # aussi contenir :text qui définit le contenu).
  def la_page_contient(sujet, balise, attrs) when is_binary(balise) and is_map(attrs) do
    session = session_from(sujet)
    found = seek_in_page(session, balise, attrs)
    assert(found, "Aucune balise #{balise} trouvée possédant les attributs #{inspect attrs}")
    sujet
  end
  def la_page_contient(sujet, balise, searched) when is_binary(balise) and (is_binary(searched) or is_struct(searched, Regex)) do
    session = session_from(sujet)
    assert Enum.any?(WB.all(session, css(balise)), fn el -> 
      Regex.match?(searched, WE.text(el))
    end)
    sujet
  end

  def la_page_contient(sujet, liste) when is_list(liste) do
    la_page_contient(sujet, liste, %{})
  end

  def la_page_contient(sujet, searched) when is_binary(searched) or is_struct(searched, Regex) do
    session = session_from(sujet)
    searched = if is_binary(searched) do
      ~r/#{Regex.escape(searched)}/
    else searched end

    # IO.inspect(WB.page_source(session), label: "\n\n+++ PAGE COMPLÈTE", printable_limit: :infinity)
    err_msg = IO.ANSI.red() <> "On devrait trouver #{inspect searched} dans la page. La page contient : #{inspect WB.all(session, css("body")) |> Enum.at(0) |> WE.text()}" <> IO.ANSI.reset()
    assert(Regex.match?(searched, WB.page_source(session)), err_msg)
    sujet
  end


  @doc """
  Pour tester que la page ne contienne pas les éléments spécifiés.
  Ces élément peuvent être spécifiés par :
    - du simple texte
    - une expression régulière
    - une balise (avec id/class) et du texte
    - une balise (avec id/class et une expresssion régulière
    - une balise et des attributs spécifiés ainsi que des propriétés
      supplémentaires comme le nombre d'élément à trouver TODO
  """
  def la_page_ne_contient_pas(sujet, tag, attrs) when is_map(attrs) do
    session = session_from(sujet)
    refute(seek_in_page(session, tag, attrs), "La page ne devrait pas contenir de balise #{tag} répondant aux attributs #{inspect attrs}.")
    sujet
  end
  def la_page_ne_contient_pas(sujet, tag, searched) when is_struct(searched, Regex) do
    session = session_from(sujet)
    founds = 
      WB.all(session, css(tag))
      |> Enum.filter(fn el -> 
        Regex.match?(searched, WE.text(el))
      end)
    assert(Enum.empty?(founds), "Aucune balise #{tag} contenant #{inspect searched} n'aurait dû être trouvée.")
    sujet
  end
  def la_page_ne_contient_pas(sujet, balise, string) when is_binary(string) do
    la_page_ne_contient_pas(sujet, balise, ~r/#{Regex.escape(string)}/)
  end
  def la_page_ne_contient_pas(sujet, searched) when is_struct(searched, Regex) do
    session = session_from(sujet)
    err_msg = IO.ANSI.red() <> "On ne devrait pas trouver #{inspect searched} dans la page. La page contient : #{inspect WB.all(session, css("body")) |> Enum.at(0) |> WE.text()}" <> IO.ANSI.reset()
    assert(not Regex.match?(searched, WB.page_source(session)), err_msg)
    sujet
  end
  def la_page_ne_contient_pas(sujet, string) when is_binary(string) do
    la_page_ne_contient_pas(sujet, ~r/#{Regex.escape(string)}/)
  end



  defp seek_in_page(session, balise, attrs) do
    Enum.any?(WB.all(session, css(balise)), fn el ->
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

  end

end