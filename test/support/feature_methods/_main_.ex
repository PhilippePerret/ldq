
defmodule FeaturePublicMethods do
  use LdQWeb.FeatureCase, async: false
  alias Wallaby.Browser,  as: WB
  alias Wallaby.Query,    as: WQ
  alias Wallaby.Element,  as: WE

  alias Feature.FormTestMethods, as: Form
  alias Feature.PageTestMethods, as: Page
  alias Feature.ActionTestMethods, as: Act

  import TestHelpers

  @doc """

  @param {Session}  ses La session
  @param {String}   url L'url à rejoindre
  @param {String}   msg À ajouter au message "Je rejoins la page {url}"
  """
  def je_rejoins_la_page(ses, url, msg \\ nil), do: Act.je_rejoins_la_page(ses, url, msg)

  @doc """
  Pour cliquer sur un bouton dans la page

  @param {Wallaby.Session} ses La session courante
  @param {String} btn Nom du bouton, on son "#id"

  @return {Wallaby.Session}
  """
  def je_clique_le_bouton(ses, but), do: Act.je_clique_le_bouton(ses, but)

  @doc """
  Pour cliquer un lien <a ...>tit</a>

  @param {Wallaby.Session} ses La session courante
  @param {String} tit Le titre du lien ou son "#id"

  @return {Wallaby.Session}
  """
  def je_clique_le_lien(ses, tit), do: Act.je_clique_le_lien(ses, tit)


  # ---- Méthodes de test --------

  @doc """
  Recherche d'un contenu dans la page, toujours à l'intérieur d'une
  balise.
  """
  def la_page_contient(session, balise, attrs), do: Page.la_page_contient(session, balise, attrs)
  def la_page_contient(session, string), do: Page.la_page_contient(session, string)

  # --- Méthodes publiques de formulaire ---

  def je_remplis_le_champ(session, champ), do: Form.je_remplis_le_champ(session, champ)
  def avec(fonction, value), do: Form.avec(fonction, value)

  @doc """
  Pour choisir un item (option) dans un menu (select)

  @param {Wallaby.Session} ses La session courante
  @param {String} opt_val La valeur (value) de l'option (pas le texte affiché, apparemment)
  @param {String} sel_id  L'identifiant (sans #) du select, optionnellement

  @return {Wallaby.Session} La session courante
  """
  def choisir_le_menu(ses, opt_val, sel_id \\ nil), do: Form.choisir_le_menu(ses, opt_val, sel_id)

  @doc """
  Pour régler le bon captcha dans le formulaire

  @param {Wallaby.Session} ses La session courante
  @param {Map} pms Paramètres supplémentaires, par exemple :form_id s'il y a plusieurs formulaire
  
  @return {Wallaby.Session}
  """
  def je_mets_le_bon_captcha(ses, pms \\ %{}), do: Form.je_mets_le_bon_captcha(ses, pms)


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
  def detruire_les_mails, do: TestMailMethods.exec_delete_all_mails()


  def rejoint_le_lien_du_mail({destinataire, mails}, link_title) do
    TestMailMethods.get_lien_in_mail_and_visit(destinataire, link_title, mails)
  end
end