
defmodule FeaturePublicMethods do
  use LdQWeb.FeatureCase, async: false
  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  import TestHelpers
  # import TestMailMethods

  def je_rejoins_la_page(session, url, added_to_msg \\ nil) do
    msg = "-> Je rejoins la page #{url} #{added_to_msg}"
    w msg, :blue
    WB.visit(session, url)
  end

  def je_remplis_le_champ(session, champ) do
    fn valeur ->
      fill_in(session, WQ.text_field(champ), with: valeur)
    end    
  end
  def avec(fonction, value) do
    fonction.(value)
  end

  def je_coche_la_case(session, case_name) do
    click(session, WQ.checkbox(case_name))
  end

  def je_clique_le_bouton(session, button_name) do
    click(session, WQ.button(button_name))
  end

  def je_clique_le_lien(session, link_title) do
    click(session, WQ.link(link_title))
  end


  # ---- Méthodes de test --------

  @doc """
  Recherche d'un contenu dans la page, toujours à l'intérieur d'une
  balise.
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

  # --- Méthodes publiques de mails ---
  # Note : On doit les mettre ici car l'import de module n'est pas
  # transitif

  @doc """
  @params {Map|User} who Définition du destinataire
  @params {Map} Table des paramètres. On peut définir :
    :after    {NaiveDateTime} Le mail doit avoir été envoyé après
    :mail_id  {String} Identifiant du mail
    :sender   {String|Atom} Le mail de l'expéditeur ou son symbol (pe. :admin)
    :count    {Integer} Nombre de mails à trouver 
    :subject  {String|Array of Strings|Regexp} Le sujet à trouver ou des segments
    :content  {String|Array of Strings|Regepx} Le contenu ou des segments

  @return {%{destinataire}|%User{destinataire}, [mails]}
  """
  def recoit_un_mail(who, params), do: TestMailMethods.user_recoit_un_mail(who, params)
  def recois_un_mail(who, params), do: TestMailMethods.user_recoit_un_mail(who, params)
  def recoivent_un_mail(who, params), do: TestMailMethods.recoit_un_mail(who, params)
  def recoit_un_mail(:admin, params), do: TestMailMethods.admin_recoit_un_mail(params)
  def detruire_les_mails, do: TestMailMethods.exec_delete_all_mails()


  def rejoint_le_lien_du_mail({destinataire, mails}, link_title) do
    TestMailMethods.get_lien_in_mail_and_visit(destinataire, link_title, mails)
  end
end