
defmodule FeaturePublicMethods do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers, only: [pause: 2]
  alias Feature.UserTestMethods,    as: U
  alias Feature.FormTestMethods,    as: Form
  alias Feature.PageTestMethods,    as: Page
  alias Feature.ActionTestMethods,  as: Act
  alias Feature.MailTestMethods,    as: Mail
  alias Feature.LogTestMethods,     as: Log
  alias Feature.SessionMethods,     as: Sess
  alias Feature.ProcedureTestMeths, as: Proc
  alias Feature.BookTestMeths     , as: Book
  alias LdQ.ComptesFixtures       , as: Compt
  alias LdQ.LibraryFixtures       , as: Lib
  alias LdQ.TriggerTestMethods    , as: Trig
  alias LdQ.ProcedureFixture      , as: FProc

  def now(type \\ :naive) do
    case type do
      :naive -> NaiveDateTime.utc_now()
      :date  -> Date.utc_now()
    end
  end

  def ilya(quantity, unity) do
    NaiveDateTime.add(now(), -quantity, unity)
  end

  def make_admin_with_session(attrs \\ %{}) do
    start_session(make_admin(attrs), [])
  end
  def get_admin_with_session(options \\ %{}) do
    raise "À implémenter"
  end
  def make_membre_with_session(attrs \\ %{}) do
    start_session(make_membre(attrs), [])
  end
  def get_membre_with_session(params \\ %{}) do
    start_session(get_membre(params), [])
  end
  def make_writer_with_session(attrs \\ %{}) do
    start_session(make_writer(attrs), [])
  end
  def make_user_with_session(attrs \\ %{}) do
    start_session(make_simple_user(attrs), [])
  end
  def get_user(user_id) do
    LdQ.Comptes.get_user!(user_id)
  end
  def get_user_with_session(user_id) when is_binary(user_id) do
    start_session(get_user(user_id), [])
  end
  def get_user_with_session(%LdQ.Comptes.User{} = user) do
    start_session(user, [])
  end


  @doc """
  @param {Map} attrs Le données transmise
    :not    Un identifiant pour ne pas prendre ce membre-là
    :id     Prendre ce membre là
    :min_credit   Le crédit minimum que doit avoir le membre
    :max_credit   Le crédit maximum que doit avoir le membre
  @return un membre (et le crée si nécessaire)
  """
  def get_membre(params \\ %{}), do: Compt.get_membre(params)
  def get_admin(params \\ %{email: "admin@lecture-de-qualite.fr"}), do: Compt.get_admin(params)
  def get_author(author_id), do: LdQ.Library.get_author!(author_id)

  def make_simple_user(attrs \\ %{}), do: Compt.make_simple_user(attrs)
  def make_user(attrs \\ %{}), do: Compt.make_simple_user(attrs)
  def make_admin(attrs \\ %{}), do: Compt.make_admin(attrs)
  def make_writer(attrs \\ %{}), do: Compt.make_writer(attrs)
  def make_author(attrs \\ %{}), do: Compt.make_author(attrs)
  def make_membre(attrs \\ %{}), do: Compt.make_membre(attrs)

  def make_book(params \\ []), do: Lib.make_book(params)
  def make_books(params \\ []), do: Book.make_books(params)
  def make_publisher(attrs \\ %{}), do: Lib.make_publisher(attrs)

  def start_session(sujet, params), do: Sess.start_session(sujet, params)
  def start_session(params), do: Sess.start_session(params)
  def start_session(), do: Sess.start_session([])
  
  def end_session(sujet), do: Sess.end_session(sujet)
  def se_deconnecte(sujet), do: Sess.end_session(sujet)

  @doc """
  Pour déplacer la fenêtre

  @param {User augmenté} sujet
  @param {Keyword} position [:left, :top]
  """
  def move_window(sujet, position), do: Sess.move_window(sujet, position)

  @doc """
  Lorsque l'on a plusieurs sessions active, on peut vouloir ramener
  une page devant l'autre
  """
  def focus(sujet), do: Page.focus(sujet)


  @doc """
  Pour rejoindre une page sur le site.

  ## Usage

    user
    |> rejoint_la_page(url)

  Pour que ça fonctionne, il faut que +suj+ possède sa session. Ça 
  peut se faire de cette manière avec la session courante :
  OBSOLÈTE : Maintenant, la session est ajoutée si elle n'est pas
  définie. Mais pour pouvoir récupérer la session (ou plutôt : pour
  pouvoir récupérer un user avec session), il faut faire :

      user = user |> rejoint_la_page(url)

  ou avec une nouvelle session

    test "mon test" do
      user = make_admin()
      {:ok, sess} = Wallaby.start_session()
      user = Map.put(user, :session, sess)
      user |> rejoint_la_page(url)
    end
  """
  def rejoint_la_page(suj, url, msg \\ nil), do: Act.visiter_la_page(suj, url, msg)

  @doc """
  Fonction permet à l'utilisateur de se connecter.
  Soit il se trouve déjà sur la page d'identification (parce qu'il a été
  redirigé) soit il rejoint l'identification)

  @return Le visiteur (avec :identified à true)
  """
  def se_connecte(visiteur) when is_map(visiteur) or is_struct(visiteur, User) do
    if not Page.on_login_page?(visiteur) do
      visiteur
      |> rejoint_la_page("/users/log_in")
      # |> pause(1)
    end
    visiteur
      |> et_voit("input", %{type: "email", id: "user_email", name: "user[email]"})
      |> remplit_le_champ("Mail") |> avec(visiteur.email)
      |> remplit_le_champ("Mot de passe") |> avec(visiteur.password)
      |> pause(1)
      |> clique_le_bouton("Se connecter")
      |> pause(1)
      |> Map.put(:identified, true)
      # |> IO.inspect(label: "VISITEUR APRÈS CONNEXION")
  end

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


  # ---- Méthodes de vérification --------

  @doc """
  Recherche d'un contenu dans la page, à l'aide d'une balise ou non.

  On peut utiliser :

  et_voit("un texte")   Pour un texte tel quel dans la page
  et_voit("h2", "un texte")   Pour un texte dans une balise h2
  et_voit("h2", %{id: "sonId", class: "saClass"}) Pour une balise  avec identifiant et classe

  """
  def la_page_contient(session, balise, attrs), do: Page.la_page_contient(session, balise, attrs)
  def et_voit(suj, balise, attrs), do: Page.la_page_contient(suj, balise, attrs)
  def la_page_contient(session, string), do: Page.la_page_contient(session, string)
  def et_voit(suj, string), do: Page.la_page_contient(suj, string)
  def la_page_contient_le_bouton(session, bouton, params \\ %{}), do: Page.la_page_contient(session, "button", bouton, params)
  def et_voit_le_bouton(suj, bouton, params \\ %{}), do: la_page_contient_le_bouton(suj, bouton, params)
  
  @doc """
  Les méthodes négatives

  NB : Pour ajouter des attributs, utiliser plutôt tag.<class>#<id> etc.
  """
  def et_ne_voit_pas(suj, tag, content), do: Page.la_page_ne_contient_pas(suj, tag, content)
  def et_ne_voit_pas(suj, str_or_reg), do: Page.la_page_ne_contient_pas(suj, str_or_reg)
  
  @doc """
  Pour créer une procédure dans la base et la retourner
  @param {String}  params Ça peut être seulement le type de la procédure (nom du dossier)
         {Keyword} params Ou une liste des propriétés
                    :proc_dim     Le nom de la procédure
                    :owner_type   {String} Le type du possesseur (p.e. "book")
                    :owner_id     {Binary} L'ID du possesseur
  """
  def make_procedure(params), do: FProc.create_procedure(params)

  @doc """
  Pour vérifier que l'user +suj+ n'a plus la procédure d'identifiant
  +pi+, qu'elle est détruite, en fait.
  """
  def has_no_procedure(suj, pid), do: Proc.has_no_procedure(suj, pid)

  @doc """
  Retourne la dernière procédure du sujet +suj+
  """
  def last_procedure_of(suj, proc_dim), do: Proc.get_last_procedure_of(suj, proc_dim)

  @doc """
  Pour vérifier que l'user a le niveau de privilège spécifié
  """
  def has_privileges(suj, priv), do: U.has_privileges(suj, priv)
  def has_not_privileges(suj, priv), do: U.has_not_privileges(suj, priv)

  # --- Méthodes publiques de formulaire ---

  def remplit_le_champ(suj, champ), do: Form.remplir_le_champ(suj, champ)
  def avec(fonction, value), do: Form.avec(fonction, value)


  @doc """
  Pour cliquer sur un bouton dans la page.
  Il s'agit soit d'un <button> soit d'un <a.btn>

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
  def clique_le_lien(suj, tit, params \\ []), do: Act.cliquer_le_lien(suj, tit, params)

  @doc """
  Pour choisir un item (option) dans un menu (select)

  @param {Wallaby.Session} ses La session courante
  @param {String} opt_val La valeur (value) de l'option (pas le texte affiché, apparemment)
  @param {String} sel_id  L'identifiant (sans #) du select, optionnellement

  @return {Wallaby.Session} La session courante
  """
  def choisit_option(suj, option_value, select_id \\ nil), do: Form.choisir_menu(suj, option_value, select_id)

  def choisit_le_menu(suj, select_ref, option_value), do: Form.choisir_le_menu(suj, select_ref, option_value)

  def coche_la_case(suj, case_name), do: Form.cocher_la_case(suj, case_name)

  @doc """
  Coche un bouton radio
  Pour le moment, il faut obligatoirement que le bouton radio ait un 
  identifiant unique précis (composé le plus souvent avec sa valeur)
  """
  def coche_le_choix(suj, radio_id), do: Form.coche_le_button_radio(suj, radio_id)
  
  @doc """
  Pour régler le bon captcha dans le formulaire

  @param {Wallaby.Session} ses La session courante
  @param {Map} pms Paramètres supplémentaires, 
    par exemple 
      :form_id et :prefix s'il y a plusieurs formulaire (dans la 
      définition du formulaire ces deux informations doivent être
      fournies)
  
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
  @doc """
  Détruit tous les mails. Maintenant qu'ils sont consignés dans la
  base de données, ils sont détruits automatiquement à chaque nouveau
  test.
  """
  def detruire_les_mails, do: Mail.exec_delete_all_mails()

  @doc """
  S'assure que le mailing a été envoyé

  @param {Atom}     d Le goupe auquel les mails sont envoyés (:college1, :admins, etc.)
  @param {String}   m ID du mail envoyé (son nom dans le dossier)
  @param {Keyword}  o Table d'options supplémentaires (non utilisé pour le moment)
  """
  def assert_mailing_sent(d, m, o \\ []), do: Mail.assert_mailing_sent(d,m,o)

  @doc """
  Assertion de l'existence d'une activité. Raise une erreur si 
  l'activité n'est pas trouvée. Si l'activité existe, retourne nil
  
  @param {Keyword} params Table des paramètres dont :
    after:      {NaiveDateTime} Le log doit avoir été émis après cette date naïve
    content:    {String|Regex}  Le log doit contenir ce texte
    owner:      {User} Le propriétaire du log
    public:     {Boolean} True si l'activité doit être publique
  """
  def check_activities(params), do: Log.check_activities(params)
  def assert_activity(params), do: Log.check_activities(params)
  
  @doc """
  Pour tester le log (activité) dans le pipe des vérifications

  @param {Keyword} params Liste des paramètres
    :as       {Atom} soit :creator soit rien (ou :owner) pour préciser le rôle de l'user (le sujet)
    :content  {String} Ce que doit contenir (extrait) l'acitivté
    :after    {NaiveDateTime} Doit avoir été émis après cette date
    :public   {Boolean} Pour savoir si l'activité doit être publique ou non
  """
  def has_activity(suj, params), do: Log.has_activity(suj, params)


  @doc """
  S'assure que le livre défini par les paramètres +params+ (contenant
  en général :author_email, :after et :title) existe bien.

  @param {Keyword} params Les paramètres de la recherche
    params[:after]  Le(s) livre(s) doit avoir été enregistré après cette date
    params[:full]   Toutes les cartes du livre doivent avoir été créées (miniCard, specs, evaluation)
    params[:count]  Le nombre de livres trouvés
    params[:author_id] L'identifiant binaire de l'auteur du livre
    params[:author_email] L'adresse email de l'auteur du livre

  @return {Book} Le livre trouvé
  """
  def assert_book_exists(params), do: Book.assert_book_exists(params)

  @doc """
  S'assure que l'auteur existe

  @return {Map} La table de toutes les données
  """
  def assert_author_exists(params), do: U.assert_author_exists(params)


  def assert_trigger(params), do: Trig.assert_exists(params)
  def refute_trigger(params), do: Trig.assert_exists(Keyword.put(params, count: 0))

  @doc """
  S'assure qu'une ligne de journal a été enregistrée pour le trigger 
  (ou pas)

  @param {Keyword} params Paramètres spécifiant le log
    :after      {NaiveDateTime} Date après laquelle le log doit avoir été émis
    :type       {String} Le type du trigger (pourrait être aussi dans :content)
    :type_trig  {String} idem que précédent
    :type_op    {String} Le type de l'opération (pour savoir si c'est un enregistrement de trigger, un check, une suppression, etc.)
    :content    {String|List} Liste des textes à trouver (ou texte à trouver)
  """
  def assert_trigger_log(params), do: Trig.assert_log(params)
  def refute_trigger_log(params), do: Trig.assert_log(Keyword.put(params, count: 0))

  # ========= POUR LES FICHIERS =========
  def depose_les_fichiers(suj, files, field) when is_list(files) do
    files = Enum.map(files, fn file -> {:path, file} end)
    Form.deposer_les_fichiers(suj, files, field)
  end
  def depose_le_fichier(suj, file, field) when is_binary(file) do
    Form.deposer_les_fichiers(suj, [path: file], field)
  end
end