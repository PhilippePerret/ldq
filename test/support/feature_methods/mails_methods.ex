defmodule Feature.MailTestMethods do
  use LdQWeb.FeatureCase, async: false

  alias LdQ.Constantes
  alias LdQ.Comptes.User

  import TestHelpers # w() etc.
  # import TestStringMethods # string_contains etc.
  import FeaturePublicMethods # Méthodes je_rejoins, etc.

  import Feature.PageTestMethods, only: [on_login_page?: 1]

  @doc """
  Méthode qui teste que le +destinataire+ a bien reçu le message de 
  sujet +subject+ possédant le contenu +contenu+

  Principes :
    - on détruit le mail ou les mails dès qu'ils ont été trouvés

  @param {Map} destinataire -- map contenant au moins {:email, :name}
  @param {String} subject Le sujet du message
  @param {List>String} contenu Liste des portions de textes à trouver. Ça peut être du simple texte ou une expression régulière.

  @return {destinataire, [mails trouvés]}
  """
  def user_recoit_un_mail(destinataire, params) when (is_map(destinataire) or is_struct(destinataire, User)) and is_map(params) do 
    params = defaultize_mail_params(params)
    mails_found = get_mails_to(destinataire, params)

    nombre_mails_found = Enum.count(mails_found)
    aucun_mail_trouved = nombre_mails_found == 0

    if aucun_mail_trouved && params.count != 0 do
      w("\n\n##### PROBLÈME DE MAILS AVEC PARAMS #{inspect params}", :red)
    end

    if is_nil(params.count) do
      msg_err = IO.ANSI.red() <> "Aucun mail trouvé répondant aux paramètres : \nDestinataire : #{inspect destinataire}\nParamètres attendus : #{inspect params}" <> IO.ANSI.reset()
      assert Enum.any?(mails_found), msg_err
    else
      s = if params.count > 1, do: "s", else: ""
      msg_err = IO.ANSI.red() <> "On devait trouver #{params.count} mail#{s}, on en a trouver #{nombre_mails_found} pour \nDestinataire : #{inspect destinataire}\nParamètres attendus : #{inspect params}." <> IO.ANSI.reset()
      assert nombre_mails_found == params.count, msg_err
    end

    # On retourne un User augmenté, avec ses mails
    Map.put(destinataire, :mails, mails_found)

  end
  def user_recoit_un_mail(who, params) when is_list(params) do
    params = Enum.reduce(params, %{}, fn {key, value}, coll ->
      Map.put(coll, key, value)
    end)
    user_recoit_un_mail(who, params)
  end
  def user_recoit_un_mail(:admin, params) do
    user_recoit_un_mail(%{name: "Administration", email: Constantes.get(:mail_admins)}, params)
  end


  @doc """
  S'assure qu'un mailing a bien été envoyé

  @param {Atom} dest_id   Le groupe des destinataires (:admins, :college1, etc.)
  @param {String} mail_id ID du mail dans le dossier
  @param {Keyword} options Table des options éventuelles (non utilisé pour le moment)
  """
  def assert_mailing_sent(dest_id, mail_id, options \\ []) do
    receiver = "Groupe mailing #{inspect dest_id}"
    options = Keyword.put(options, :mail_id, mail_id)
    mails = get_mails_to(receiver, options)
    assert(Enum.count(mails) == 1, "On aurait dû trouver un mailing pour le groupe #{inspect dest_id} d'identifiant #{inspect mail_id}…")
  end

  @doc """
  Récupère tous les mails au +destinataire+ qui répondent aux
  paramètres +params+ et retourne une table de résultat détaillée.

  Note : Pour n'obtenir que les mails, ajouter un "!"

  @param {User augmenté} destinataire L'instance User du destinataire
  @param {Map} params Table des filtres (avec :after, :content, etc. -- cf. la méthode get_mails_against_params/1 pour voir le détail)

  @return {Map} Une table avec les résultats complets (cf. get_mails_against_params/1 pour le détail)
  """
  def get_mails_to(destinataire, params \\ %{}) do
    params = Phil.Map.ensure_map(params)
    destin =
      cond do
        is_binary(destinataire) -> destinataire
        Map.get(destinataire, :mail) -> Map.get(destinataire, :mail)
        Map.get(destinataire, :email) -> Map.get(destinataire, :email)
        true -> raise "Destinataire mail défini. Ça devrait être l'adresse courriel ou une map contenant :mail ou :email"
      end
    params = Map.put(params, :to, destin)
    get_mails_against_params(params)
  end

  @doc """
  Méthode d'API qui ne retourne que la liste des mails du desinataire
  et seulement les mails correspondant aux paramètre +params+ (qui se
  limitent souvent à %{after: <date>})
  """
  def get_mails_to!(destinataire, params \\ %{}) do
    get_mails_to(destinataire, params).keptmails
  end

  @doc """
  Filtre complet et détaillé des mails envoyés répondant à +params+

  @param {Map} params Paramètres complet du filtre
    params.to       Les mails doivent être reçus par lui
    params.after    Les mails doivent avoir été envoyés après cette date (et strictement après cette date)
    params.from     Les mails doivent avoir été envoyés par ce sender
    params.mail_id  {String} Le mail doit avoir cet identifiant.
    params.subject  {String|Regex|List of this} Le sujet du mail doit contenir ce ou ces éléments.
    params.body     {String|Regex|List of this} Le corps du message doit contenir ce ou ces éléments.

  @return {Map} res une table contenant les mails
  """
  def get_mails_against_params(params) do
    params = defaultize_mail_params(params)
    # On prend tous les mails dans la table
    LdQ.Tests.Mails.find(params)
    # |> IO.inspect(label: "Tous les mails filtrés")
  end

  @doc """
  Prend le premier mail de la liste +mails+ reçue par le 
  +destinataires+, relève l'href du lien de titre +link_title+ et le
  visite.

  Pour l'utiliser dans une chaine de pipe, on utilise la méthode 
  publique :
    admin
    |> rejoint_le_lien_du_mail("titre du lien")

  @param {User|Map} destinataire. Le destinataire. Il faut au moins que la map contienne :email et :password pour que l'utilisateur puisse se connecter au besoin.
  @param {String} link_title Le titre du lien
  @param {Array>Map} mails Liste de tous les mails reçus.

  @return destinataire (qui définit :session, La session initiée)
  """
  def get_lien_in_mail_and_visit(destinataire, link_title, mails) do
    mail = Enum.at(mails, 0)
    body = mail.html_body
    href =
    Regex.scan(~r/<a .*href="(.+)".*>#{link_title}<\/a>/U, body)
    |> Enum.at(0)
    |> Enum.at(1)
    |> IO.inspect(label: "\nLien à atteindre")

    # Le destinataire rejoint la page
    destinataire =
      destinataire
      |> rejoint_la_page(href)
      |> pause(1)

    # Peut-être qu'il doit s'identifier
    if on_login_page?(destinataire) do
      destinataire |> se_connecte()
    else 
      destinataire 
    end
  end

  # ---- Sous-méthodes privées ----

  def admin_recoit_un_mail(params) do
    user_recoit_un_mail(%{email: "admin@lecture-de-qualite.fr", name: "Admin"}, params)
  end

  def exec_delete_all_mails do
    LdQ.Tests.Mails.delete_all()
  end

  # Fonction pour extraire une adresse de courriel dans la table 
  # +map+ avec les clés +keys
  # 
  # @param {Map} map Table pouvant contenir beaucoup de choses
  # @param {List} keys Liste des clés qui peuvent contenir un mail
  defp extract_email_from(map, keys) do
    candidat = 
      Enum.reduce(keys, nil, fn key, cur_value ->
        if is_nil(cur_value) do
          Map.get(map, key, nil)
        else cur_value end
      end)
    cond do
      is_nil(candidat)          -> nil
      is_binary(candidat)       -> candidat
      Map.get(candidat, :mail)  -> Map.get(candidat, :mail)
      Map.get(candidat, :email) -> Map.get(candidat, :email)
      true -> raise "Impossible de trouver le mail dans #{inspect map} avec les clés #{inspect keys}"
    end
  end
  # Pour simplifier et clarifier
  defp defaultize_mail_params(params) do
    the_to = extract_email_from(params, [:receiver, :to])
    the_from = extract_email_from(params, [:from, :sender])
    Map.merge(%{
      to:       the_to,
      from:     the_from,
      mail_id:  nil,
      subject:  nil,
      body:     Map.get(params, :content),
      after:    nil,
      count:    1
    }, params)
  end

end