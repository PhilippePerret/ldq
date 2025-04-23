
defmodule FeaturePublicMethods do
  use LdQWeb.FeatureCase, async: false
  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  import TestHelpers
  import TestMailMethods

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


  # ---- Méthodes de test --------

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
  @params {Map} who Définition du destinataire
  @params {Map} Table des paramètres. On peut définir :
    :after    {NaiveDateTime} Le mail doit avoir été envoyé après
    :mail_id  {String} Identifiant du mail
    :sender   {String|Atom} Le mail de l'expéditeur ou son symbol (pe. :admin)
    :count    {Integer} Nombre de mails à trouver 
    :subject  {String|Array of Strings|Regexp} Le sujet à trouver ou des segments
    :content  {String|Array of Strings|Regepx} Le contenu ou des segments
  """
  def recoit_un_mail(who, params), do: user_recoit_un_mail(who, params)
  def recois_un_mail(who, params), do: user_recoit_un_mail(who, params)
  def recoivent_un_mail(who, params), do: recoit_un_mail(who, params)
  def recoit_un_mail(:admin, params), do: admin_recoit_un_mail(params)
  def detruire_les_mails, do: exec_delete_all_mails()
end