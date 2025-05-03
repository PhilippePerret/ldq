
defmodule FeaturePublicMethods do
  use LdQWeb.FeatureCase, async: false
  # alias Wallaby.Browser,  as: WB
  # alias Wallaby.Query,    as: WQ
  # alias Wallaby.Element,  as: WE

  import TestHelpers

  alias Feature.FormTestMethods,    as: Form
  alias Feature.PageTestMethods,    as: Page
  alias Feature.ActionTestMethods,  as: Act
  alias Feature.MailTestMethods,    as: Mail
  alias Feature.LogTestMethods,     as: Log
  alias Feature.SessionMethods,     as: Sess

  # import TestHelpers

  def make_admin_with_session(attrs \\ %{}) do
    Map.put(make_admin(attrs), :session, start_session())
  end
  def make_member_with_session(attrs \\ %{}) do
    Map.put(make_member(attrs), :session, start_session())
  end
  def make_writer_with_session(attrs \\ %{}) do
    Map.put(make_writer(attrs), :session, start_session())
  end
  def make_user_with_session(attrs \\ %{}) do
    Map.put(make_simple_user(attrs), :session, start_session())
  end


  def start_session(params \\ []), do: Sess.start_session(params)
  
  def end_session(sujet), do: Sess.end_session(sujet)

  @doc """
  Lorsque l'on a plusieurs sessions active, on peut vouloir ramener
  une page devant l'autre
  """
  def focus(sujet), do: Page.focus(sujet)


  @doc """
  Fonction permet à l'utilisateur de se connecter.
  Soit il se trouve déjà sur la page d'identification (parce qu'il a été
  redirigé) soit il rejoint l'identification)
  """
  def se_connecte(visiteur) when is_map(visiteur) or is_struct(visiteur, User) do
    if not Page.on_login_page?(visiteur) do
      visiteur
      |> rejoint_la_page("/users/log_in")
      |> pause(1)
    end
    visiteur
      |> et_voit("input", %{type: "email", id: "user_email", name: "user[email]"})
      |> remplit_le_champ("Mail") |> avec(visiteur.email)
      |> remplit_le_champ("Mot de passe") |> avec(visiteur.password)
      |> pause(1)
      |> clique_le_bouton("Se connecter")
      |> Map.put(:identified, true)
      # |> IO.inspect(label: "VISITEUR APRÈS CONNEXION")
  end

  @doc """
  Pour rejoindre une page sur le site.

  ## Usage

    user
    |> rejoint_la_page(url)

  Pour que ça fonctionne, il faut que +suj+ possède sa session. Ça 
  peut se faire de cette manière avec la session courante :

    test "mon test", {session: session} do
      user = make_simple_user(%{name: "André"})
      user = Map.put(user, :session, session)
      user |> rejoint_la_page(url)
    end

  ou avec une nouvelle session

    test "mon test" do
      user = make_admin()
      {:ok, sess} = Wallaby.start_session!()
      user = Map.put(user, :session, sess)
      user |> rejoint_la_page(url)
    end
  """
  def rejoint_la_page(suj, url, msg \\ nil), do: Act.visiter_la_page(suj, url, msg)

  @doc """
  Récupère un lien dans un mail (par son titre) et le visite

  @param {User augmenté} destinataire Le destinataire du mail
    Il doit impérativement avoir une propriété :mails ajouté (par une 
    autre fonction) qui contient ses mails actuels.
  @param {String} link_title Le titre du lien sur lequel on doit cliquer tel qu'il apparait dans le texte du mail
  @return {User augmenté} Une session qu'on peut donc piper.
  """
  def rejoint_le_lien_du_mail(destinataire, link_title) do
    destinataire = 
      if Map.has_key?(destinataire, :mails) do
        destinataire
      else
        Map.put(destinataire, :mails, Mail.get_mails_to!(destinataire))
      end
    Mail.get_lien_in_mail_and_visit(destinataire, link_title, destinataire.mails)
  end

  @doc """
  Pour cliquer sur un bouton dans la page

  @param {Wallaby.Session} ses La session courante
  @param {String} btn Nom du bouton, on son "#id"

  @return {Wallaby.Session}
  """
  def clique_le_bouton(suj, but), do: Act.cliquer_le_bouton(suj, but)

  @doc """
  Pour cliquer un lien <a ...>tit</a>

  @param {Wallaby.Session} ses La session courante
  @param {String} tit Le titre du lien ou son "#id"

  @return {Wallaby.Session}
  """
  def clique_le_lien(suj, tit), do: Act.cliquer_le_lien(suj, tit)


  # ---- Méthodes de test --------

  @doc """
  Recherche d'un contenu dans la page, toujours à l'intérieur d'une
  balise.
  """
  def la_page_contient(session, balise, attrs), do: Page.la_page_contient(session, balise, attrs)
  def et_voit(suj, balise, attrs), do: la_page_contient(suj, balise, attrs)
  def la_page_contient(session, string), do: Page.la_page_contient(session, string)
  def et_voit(suj, string), do: la_page_contient(suj, string)
  def la_page_contient_le_bouton(session, bouton, params \\ %{}), do: Page.la_page_contient(session, "button", bouton, params)
  def et_voit_le_bouton(suj, bouton, params \\ %{}), do: la_page_contient_le_bouton(suj, bouton, params)
  
  
  # --- Méthodes publiques de formulaire ---

  def remplit_le_champ(suj, champ), do: Form.remplir_le_champ(suj, champ)
  def avec(fonction, value), do: Form.avec(fonction, value)

  @doc """
  Pour choisir un item (option) dans un menu (select)

  @param {Wallaby.Session} ses La session courante
  @param {String} opt_val La valeur (value) de l'option (pas le texte affiché, apparemment)
  @param {String} sel_id  L'identifiant (sans #) du select, optionnellement

  @return {Wallaby.Session} La session courante
  """
  def choisit_le_menu(suj, opt_val, sel_id \\ nil), do: Form.choisir_menu(suj, opt_val, sel_id)

  def coche_la_case(suj, case_name), do: Form.cocher_la_case(suj, case_name)

  @doc """
  Pour régler le bon captcha dans le formulaire

  @param {Wallaby.Session} ses La session courante
  @param {Map} pms Paramètres supplémentaires, par exemple :form_id s'il y a plusieurs formulaire
  
  @return {Wallaby.Session}
  """
  def choisit_le_bon_captcha(suj, params \\ %{}), do: Form.mettre_bon_captcha(suj, params)

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
  def recoit_un_mail(who, params), do: Mail.user_recoit_un_mail(who, params)
  def recois_un_mail(who, params), do: Mail.user_recoit_un_mail(who, params)
  def recoivent_un_mail(who, params), do: Mail.user_recoit_un_mail(who, params)
  def detruire_les_mails, do: Mail.exec_delete_all_mails()

 
  @doc """
  @return True si le log défini par les paramètres +params+ est 
  trouvé, False dans le cas contraire.
  
  @param {Keyword} params Table des paramètres dont :
    after:      {NaiveDateTime} Le log doit avoir été émis après cette date naïve
    content:    {String|Regex}  Le log doit contenir ce texte
    owner:      {User} Le propriétaire du log
  """
  def check_activities(params), do: Log.check_activities(params)

end