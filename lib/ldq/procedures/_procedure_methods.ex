defmodule LdQ.ProcedureMethods do
  @moduledoc """
  Gestion des procédures
  """

  import Ecto.Query, warn: false
  alias LdQ.{Repo, Comptes, Notification, Constantes, Procedure}
  alias LdQ.Comptes.User

  # import Html.Helpers

  def __run__(module, procedure) do
    # IO.inspect(procedure, label: "\nJOUER LA PROCÉDURE")
    run_current_procedure(procedure, module, module.steps())
  end

  def now do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
  end

  # @doc """
  # Pour utiliser les féminines dans les messages 
  
  # NB : Il est question ici des messages "directs", construits dans
  # les fonctions. Pour les mails et les textes par fichier, utiliser
  # l'envoi de variables.
  # """
  # def fem(id, sexe) when is_atom(id) and is_binary(sexe) do
  #   Helpers.Feminines.fem(id, sexe)
  # end
  # def fem(id, user) when is_atom(id) and is_struct(user, User) do
  #   fem(id, user.sexe)
  # end

  @doc """
  @return True si l'user courant est administrateur
  """
  def current_user_is_admin?(procedure) do
    Comptes.User.admin?(procedure.current_user)
  end

  @doc """
  Retourne le texte contenu dans le fichier spécifié, après l'avoir
  interprété en PhilHtml (s'il a besoin d'être actualisé)

  Le fichier doit obligatoirement se trouver dans un dossier "textes"
  de la procédure.

  Note : les helpers sont transmis, à savoir : 
    Helpers.Feminines
    LdQWeb.ViewHelpers
    et d'autres je crois

  @param {String} folder Le dossier de la procédure (__DIR__)
  @param {String} root_name Le nom racine du fichier (donc sans extension)
  @param {Keyword} vars Liste des variables à utiliser
                    Si :user est renseigné, la fonction ajoute automatiquement les variables user_name, user_mail et user_id
  """
  def load_phil_text(folder, root_name, vars \\ %{}) do
    path = Path.join([folder, "textes", "#{root_name}.phil"])
    vars = 
      if Map.has_key?(vars, :user) do
        vars
        |> Map.merge(Helpers.Feminines.as_map(vars.user.sexe))
        # La table ci-dessus contient tous les suffixes féminins ou
        # masculins suivant l'user, préfixés par "f_". Pour le "e" de
        # "ami" ou "amie" par exemple, c'est "f_e". Donc on doit mettre
        # dans le message « C'est mon ami<:: f_e ::> »
        |> Map.merge(%{
          user_name:  vars.user.name,
          user_email: vars.user.email, user_mail: vars.user.email,
          user_id:    vars.user.id,
          user_sexe:  vars.user.sexe
        })
      else 
        vars 
        |> Map.merge(Helpers.Feminines.as_map("H"))
      end
    options = philhtml_options(variables: vars)
    # |> IO.inspect(label: "\nOPTIONS in load_phil_text")
    PhilHtml.to_html(path, options)
    # |> IO.inspect(label: "\n\nRETOUR DE PHILHTML dans load_phil_text")
  end

  @doc """
  Pour ajouter un trigger (cf. dans le fichier trigger.ex à quoi ils
  servent)

  @param {String} type Le type, qui doit être défini dans les données absolues des triggers (fichier trigger_absdata.ex)
  @param {Map} data Les données à enregistrer avec le trigger, à commencer par les :required_data des définitions absolues des triggers
  @param {Binary} marker_id Identifiant du "marqueur" (celui qui génère le marqueur)
  """
  def add_trigger(type, data, marker_id) do
    LdQ.Core.Trigger.pose_trigger(type, data, [marked_by: marker_id])
  end

  @doc """
  Pour enregistrer une activité
  -----------------------------
  @param {Map} params Les paramètres requis par %LdQ.Site.Log{}. Cf. lib/site/log.ex
    :public     {Boolean}   True/False pour savoir si c'est une annonce publique
    :text       {String}    Le texte exact et formaté en HTML du message
    :owner_type {String}    Type du propriétaire (souvent "book" ou "user")
    :owner_id   {Binary}    Identifiant binaire du propriétaire
    :creator    {User}      Le créateur du message, simple user ou administrateur
  """
  def log_activity(params) do
    case LdQ.Site.Log.create(params) do
    {:ok, _changeset} -> true
    {:error, _changeset} -> 
      # TODO Prévenir l'administration du site
      false
    end
  end

  @doc """
  Pour obtenir un lien vers la procédure pour le mail, donc vers une
  adresse absolue.

  @param {Procedure} procedure  La procédure pour laquelle il faut retourner une url
  @param {Keyword} params Les paramètres à prendre en compte
    params[:query_string] Query string à ajouter ("sans ?")
    params[:title] Le titre du lien
    params[:style] Le style éventuel

  @return {HTMLString} Le string complet <a ...>...</a> à coller.
  """
  def proc_url(procedure, params \\ []) do
    href  = [Constantes.get(:app_url), "proc", procedure.id] |> Enum.join("/")
    title = Keyword.get(params, :title, "Rejoindre la procédure ")
    # - Ajout du query string au besoin (pour nstep par exemple)
    href =
      if params[:query_string] do
        "#{href}?#{params[:query_string]}"
      else href end
    style =
      if params[:style] do 
        ~s( style="#{params[:style]}")
      else "" end
    ~s(<a href="#{href}"#{style}>#{title}</a>)
  end

  @doc """
  Vérifie si le captcha du formulaire est bon.
  Si le captcha est mauvais, affiche un texte standard auquel on peut
  ajouter une précision.

  @usage :

    case check_captcha(procedure, "prefix") do
    :ok -> <la suite à jouer>
    {:error, message} -> message
    end
    /fin de procédure

  @param {Map} procedure La procédure complète
  @param {String} prefix Le préfix du formulaire (surtout lorsqu'il y en a plusieurs)
  @param {String} raison L'ajout éventuel au message
  
  @return True si le captcha est bon, False dans le cas contraire.
  """
  def check_captcha(procedure, prefix \\ "f", raison \\ nil) do
    if Html.Form.captcha_valid?(procedure.params[prefix]) do
      :ok
    else
      {
        :error,
        """
        <h2>Voie sans issue</h2>
        <p>Désolé, mais seul un humain peut effectuer cette opération.</p>
        <p>#{raison}</p>
        """
      }
    end
  end

  @doc """
  Pour vérifier si l'utilisateur courant est abilité à jouer la
  procédure voulu (donc son next_step)

  @return True si l'utilisateur courant est autorisé, False dans le
  cas contraire
  """
  def current_user_can_run_step(curuser, procedure) do
    steps = LdQ.Procedure.get_steps_of(procedure)
    step  = current_procedure(procedure, steps)
    owner = get_owner(procedure)

    !is_nil(step) || raise("Impossible de trouver l'étape suivante (next_step : #{procedure.next_step}) dans le @steps de la procédure : #{inspect procedure}")
    is_boolean(Map.get(step, :admin_required)) || raise("L'étape de procédure #{inspect step} devrait définir :admin_required")
    is_boolean(Map.get(step, :owner_required)) || raise("L'étape de procédure #{inspect step} devrait définir :owner_required")

    user_not_admin = !User.admin?(curuser)
    user_not_owner = curuser.id != owner.id

    other_validity =
      if Map.get(step, :required) do
        LdQ.Procedure.get_proc_module(procedure.proc_dim)
        |> apply(step.required, [procedure])
      else true end

    cond do
      step.admin_required && user_not_admin -> :not_admin
      step.owner_required && user_not_owner -> :not_owner
      !other_validity -> :impasse
      true -> true
    end
  end

  @doc """
  Voie sans issue
  On envoie ici un utilisateur qui n'a rien à faire à un
  endroit. Cette méthode doit alors être la dernière de l'étape.

  TODO Plus tard, on pourra faire une issue propre à une procédure en
  définissant un fichier <dossier proc>/textes/impasse.phil.
  """
  def impasse(_procedure) do
    """
    <div style="position:relative;clear:both;">
      <img src="/images/impasse.png" style="vertical-align:middle;float:left;margin-right:4em;margin-bottom:2em;" />
      <span class="bigger" style="padding:1.5em;border-radius:0.5em;position:absolute;display:block;background-color:red;color:white;left:8em;top:2em;">Il semblerait que vous n'ayez rien à faire sur cette page.</span>
    </div>
    <div style="clear:both;"> </div>
    """
  end

  @doc """
  Données par défaut pour le mail

  """
  def default_mail_data(%LdQ.Procedure{} = procedure) do
    %{
      procedure:  procedure,
      user:       get_user(procedure),
      folder:     get_folder(procedure),
      mail_id:    nil,
      variables:  %{}

    }
  end

  # Pour retourne la procédure courante (Map)
  defp current_procedure(procedure, steps) do
    current_fun = procedure.next_step |> String.to_atom()
    Enum.find(steps, fn step -> step.fun == current_fun end)
  end

  @doc """
  Pour rejouer proprement une procédure

  """
  def rerun_procedure(procedure, step_fun) do
    # IO.inspect(procedure, label: "\n\nPROCÉDURE DANS RERUN")
    # Il est peut-être normal ici d'avoir :data sous forme de string…
    # Ce sera à contrôler quand même (TODO)
    data = 
    cond do
      is_nil(Map.get(procedure, :data, nil)) -> nil
      is_binary(procedure.data) -> Jason.decode!(procedure.data)
      true -> procedure.data # logiquement une table
    end
    procedure = Map.put(procedure, :data, data)
    # IO.inspect(procedure, label: "\n\nDANS RERUN après transfo :data")
    module = LdQ.Procedure.get_proc_module(procedure.proc_dim)
    step_fun = if is_binary(step_fun), do: step_fun, else: Atom.to_string(step_fun)
    resultat = run_current_procedure(%{procedure | next_step: step_fun}, module)
    {:reran, resultat}
  end

  @doc """
  Joue l'étape désirée (next_step) de la procédure courante et retourne son résultat.

  @return {HTMLString} Le code HTML à écrire dans la page
  """
  def run_current_procedure(procedure, module, steps \\ nil) do
    current_step = current_procedure(procedure, steps || module.steps())
    current_step || raise """
    Étape de procédure #{inspect procedure.next_step} introuvable dans :
    #{inspect steps || module.steps()}
    """
    run_procedure(module, procedure, current_step)
  end

  def run_procedure(module, procedure, current_step) do
    resultat = apply(module, current_step.fun, [procedure])

    if is_binary(resultat) do
      # Condition normale, quand la fonction retourne le texte à 
      # écrire dans la page
      plain_title = plain_title(procedure, current_step)
      plain_title <> resultat
    else
      case resultat do
      {:reran, texte_final}   -> texte_final
      {:error, error_message} -> error_message
      end
    end
  end

  defp plain_title(procedure, step) do
    subtitle = if Map.get(step, :no_name) do "" else
      "<h3>#{step.name}</h3>"
    end

    """
    <h2>#{procedure.name}
      <div class="tiny">ID #{procedure.id}</div>
    </h2>
    #{subtitle}
    """
  end

  @doc """
  Retourne l'user visé par la procédure. On peut le trouver de trois
  manière différente :
    1. Il est dans une propriété user_id de la procédure (forcément
       ajoutée en cours de processus)
    2. Il est le propriétaire de la procédure
    3. Il est défini dans les data de la procédure.
  @return %Comptes.User{}
  """
  def get_owner(procedure), do: get_user(procedure)
  def get_user(procedure) do
    user_id = 
      cond do
      Map.has_key?(procedure, :user_id) -> procedure.user_id
      procedure.owner_type == "user"    -> procedure.owner_id
      Map.has_key?(procedure.data, :user_id) -> procedure.data.user_id
      true -> nil
      end

    if is_nil(user_id) do
      nil
    else
      Comptes.Getters.get_user!(user_id)
    end
  end

  @doc """
  Retourne le dossier de la procédure +procedure+
  """
  def get_folder(%LdQ.Procedure{} = procedure) do
    LdQ.Procedure.folder_procedure(procedure.proc_dim)
  end

  @doc """
  @return {HTMLString} Lien conduisant au profil de l'user +user+
  """
  def user_link(user, options \\ []) do
    attrs = 
    ["a"]
    |> append_if(~s(href="/inscrit/show/#{user.id}"), true)
    |> append_if(~s(target="_blank"), options[:target] == :blank)

    "<#{Enum.join(attrs, " ")}>#{options[:title] || user.name}</a>"
  end

  def append_if(liste, element, condition) do
    if condition do
      liste ++ [element]
    else
      liste
    end
  end

  @doc """
  Crée la procédure persistante avec les attributs voulus
  """
  def create_procedure(attrs) do
    %Procedure{}
    |> Procedure.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Pour les tests, pour obtenir une procédure à partir de ses
  @param {Keyword} params Les paramètres de recherche
      param[:owner] {Any} Le propriétaire de la procédure. On se servira seulement du owner.id
      param[:submitter] {User} La personne qui a soumis la procédure (qui l'a créée)
      param[:dim]   {String} Le proc_dim de la procédure
      param[:after] {NaiveDateTime} La procédure doit avoir été créée après cette date
      param[:last]  {Boolean} Si True, on prend la dernière et on la renvoie SEULE
      param[:one]   {Boolean} Si True, on ne retourne que la première
  @return %{Map|List of Map} Liste des procédures répondant aux paramètres +params+ OU seulement celle recherchée
  """
  def get_procedure(params) when is_list(params) do
    # - Défaultize params -
    params = 
      if Keyword.has_key?(params, :dim) do
        Keyword.put(params, :proc_dim, params[:dim])
      else params end
    # - Build request -
    query = from(p in Procedure)
    query = 
      if Keyword.has_key?(params, :owner) do
        where(query, [p], p.owner_id == ^params[:owner].id)
      else query end
    query =
      if Keyword.has_key?(params, :submitter) do
        where(query, [p], p.submitter_id == ^params[:submitter].id)
      else query end
    query =
      if Keyword.has_key?(params, :proc_dim) do
        where(query, [p], p.proc_dim == ^params[:proc_dim])
      else query end
    query = 
      if Keyword.has_key?(params, :after) do
        where(query, [p], p.inserted_at > ^params[:after])
      else query end
    query =
      if params[:last] do
        order_by(query, [p], asc: p.inserted_at)
        |> limit(1)
      else query end
    query =
      if params[:one] do
        limit(query, 1)
      else query end
    # - Relève de toutes les procédures -
    allfounds = Repo.all(query)
    |> Repo.preload(:submitter)
    |> Enum.map(fn proc ->
      Map.put(proc, :data, Jason.decode!(proc.data || "{}"))
    end)
    if params[:one] || params[:last] do
      Enum.at(allfounds, 0)
    else
      allfounds
    end
  end
  # @return Nil si la procédure n'existe pas
  def get_procedure(proc_id) do
    Procedure.get(proc_id)
  end

  def update_procedure(%Procedure{} = proc, attrs) do
    proc
    |> Procedure.changeset(attrs)
    |> Repo.update!()
  end
  # Pour éviter une erreur classique
  def update_procedure(%Procedure{}) do
    raise "Pour actualiser la procédure, il faut envoyer la procédure courante en premier argument et les modifications dans une Map en second argument."
  end

  @doc """
  Pour actualiser simplement une ou des données dans :data

  @param {Procedure} proc La procédure en question
  @param {Map} new_data Table des nouvelles données

  @return {Procedure} la procédure actualisée
  """
  def update_data_procedure(%Procedure{} = proc, new_data) do
    update_procedure(proc, %{data: Map.merge(proc.data, new_data)})
  end

  def delete_procedure(%Procedure{} = procedure) do
    Repo.delete(procedure)
  end

  # === Notifications ===

  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert!()
  end

  def get_notification(notif_id) do
    Repo.get!(Notification, notif_id)
  end

  def update_notification(%Notification{} = notif, attrs) do
    notif 
    |> Notification.changeset(attrs)
    |> Repo.update()
  end

  def delete_notification(%Notification{} = notification) do
    Repo.delete(notification)
  end

  @doc """
  En mode test, au lieu d'envoyer le mail, on l'enregistre dans la
  base de données (LdQ.Tests.Mails/tests_mails)
  """
  def consigne_mail_for_test(data_mail) do
    {_sender_name, sender_email} = data_mail.email.from
    %{
      to:           data_mail.receiver.email,
      from:         sender_email,
      mail_id:      data_mail.mail_id,
      body:         data_mail.html_body,
      attachment:   Map.get(data_mail, :attachment, nil),
      subject:      data_mail.subject
    } |> LdQ.Tests.Mails.create()
  end

  @doc """
  Pour envoyer un mail

  Par exemple :

    send_mail(to: x, from: :admin, with: %{id: "mon-mail", variables: %{...}})

  @param {String|Atom} sender du message (si :admin, c'est l'administration)
  @param {String|Atom|User|Array>Users} receiver du message (si :admins, à tous les administrateurs)
  @param {Map} params Les données du mail dont :
    :mail_id    {String} L'identifiant du mail dans son dossier
    :procedure  {Procedure} La procédure générant le mail
    :folder     {String} Le dossier dans lequel trouver le dossiers mails (en général __DIR__)
    :user       {User} l'user du mail, la cible, en général (mais pas forcément toujours le destinataire)
    :variables  {Map} Table des variables particulières
                De nombreuses variables seront ajoutées automatiquement aux mails,
                comme les féminines, les variables user (user_name, user_mail, etc.)
                Seront aussi injectée automatiquement les variables de la procédure si
                la procédure est transmise
  """
  def send_mail([to: receiver, from: sender, with: params] = _attrs) do
    LdQ.Mailer.send_phil_mail(receiver, sender, params)
  end
  def send_mail(receiver, sender, params) do
    LdQ.Mailer.send_phil_mail(receiver, sender, params)
    # data_mail = compose_mail(sender, receiver, params)

    # # Il faut modifier les propriétés de data_mail.philhtml pour que
    # # l'évaluation soit demandée
    # philhtml = data_mail.philhtml
    # philhtml = %{philhtml | options: Keyword.put(philhtml.options, :evaluation, true)}
    # data_mail = %{data_mail | philhtml: philhtml}

    # data_mail.receivers 
    # |> Enum.reduce(%{errors: [], sent: []}, fn receiver, coll ->

    #   receiver = case is_binary(receiver) do
    #     true  -> %{name: "", email: receiver, sexe: "H"}
    #     false -> receiver
    #   end

    #   # Sujet propre
    #   subject = PhilHtml.Evaluator.customize!(data_mail.subject, data_mail.philhtml)
    #   # Contenu propre
    #   # --------------
    #   # Il faut ajouter les variables féminines pour le receveur 
    #   # courant.
    #   opts = data_mail.philhtml.options
    #   opts = 
    #     opts
    #     |> Keyword.put(:variables, Helpers.Feminines.add_to(opts[:variables], receiver.sexe) )
    #   philhtml = %{data_mail.philhtml | options: opts}
    #   html_body = PhilHtml.Evaluator.customize!(data_mail.heex_body, philhtml)
      
    #   # IO.inspect(subject, label: "\n+++ SUJET PROPRE")
    #   # IO.inspect(html_body, label: "\n+++ CONTENU PROPRE")


    #   email = data_mail.email 
    #   |> Swoosh.Email.to({receiver.name, receiver.email})
    #   |> Swoosh.Email.subject(subject)
    #   |> Swoosh.Email.html_body(html_body)

    #   if Constantes.env_test? do
    #     # Mode test : consigner les données du mail
    #     data_mail = Map.merge(data_mail, %{
    #       receiver: receiver,
    #       subject:  subject,
    #       html_body: html_body
    #     })
    #     consigne_mail_for_test(data_mail)
    #   else
    #     # Envoi de l'email
    #     case LdQ.Mailer.deliver(email) do
    #       {:ok, _} -> 
    #         %{coll | sent: coll.sent ++ [email]}
    #       {:error, reason} -> 
    #         %{coll | errors: coll.errors ++ [reason]}
    #     end
    #   end
    # end)
    # # |> IO.inspect(label: "Résultat de l'envoi")
  end

  @destinataires_mailing %{
    admins: %{
      name: "Groupe des administrateurs"
    },
    college1: %{
      name: "Premier collège de lecteurs du comité"
    },
    college2: %{
      name: "Second collège de lecteurs du comité"
    },
    college3: %{
      name: "Troisième collège de lecteurs du comité"
    },
    membres: %{
      name: "Groupe de tous les membres des trois collèges confondus"
    },
    authors: %{
      name: "Groupe de tous les auteurs de livres évalués"
    },
  }
  @doc """
  Permet d'envoyer un mailing (par le biais de brevo pour le moment) 
  à un groupe identifié par +dest_id+ à partir du message d'identi-
  fiant +mail_id+ qui correspond au nom du fichier dans le dossier 
  params[:folder]
  """
  def send_mailing(dest_id, mail_id, params) do
    params[:folder] || raise("Il faut fournir le dossier de la procédure en troisième argument ([folder: __DIR__])")
    _group_data = @destinataires_mailing[dest_id] || raise("Le groupe #{inspect dest_id} est inconnu des mailing-lists…")
    
    params = Phil.Map.ensure_map(params)
    params = Map.put(params, :mail_id, mail_id)
    {phildata, _params} = get_and_formate_mail(params)


    if Constantes.env_test? do
      # En mode test, on enregistre simplement un mail dans la base
      data_mail = %{
        mail_id:  mail_id,
        email:    %{from: {"Administration", "admin@mailing.com"}},
        receiver: %{email: "Groupe mailing #{inspect dest_id}"},
        subject:  phildata.subject,
        html_body: phildata.html
      }
      consigne_mail_for_test(data_mail)
    else
      raise "Je dois apprendre à vraiment envoyer un mailing."
    end
  end

  # Fonction qui récupère et formate le message
  # @return {phildata, params} Avec params qui a été "augmenté"
  defp get_and_formate_mail(params) do
    mail_path = 
      [params.folder, "mails", "#{params.mail_id}.phil"] 
      |> Path.join 
      |> Path.absname()
    File.exists?(mail_path) || raise("Le mail #{inspect mail_path} est introuvable…")
    params    = defaultize_mail_params(params)
    variables = params.variables

    # On formate le mail
    phil_data = PhilHtml.to_data(mail_path, 
      [
        evaluation: false,
        variables: variables, 
        helpers: all_helpers()
      ])
    # |> IO.inspect(label: "\n\n+++ PHILDATA DU MAIL À ENVOYER")

    subject = Constantes.get(:mail_subject_prefix) <> (phil_data.options[:variables].subject || "(Sans objet)")

    phil_data = Map.merge(phil_data, %{
      subject: subject
    })
    {phil_data, params}
  end

  defp defaultize_mail_params(params) do
    file = Map.get(params, :attached_file, nil)

    params
    |> Map.put(:attached_file, file)
    |> add_common_mail_variables()
  end

  defp add_common_mail_variables(params) do
    variables = Map.get(params, :variables, %{})

    variables = Map.merge(variables, %{
      ldq_logo: "[LE LOGO DU LABEL]",
      ldq_label: ~s(<span class="label">Label de Qualité</span>)
    })
    # - Utilisateur -
    user = cond do
      Map.get(params, :user) -> params.user
      Map.get(params, :user_id) ->
        Comptes.Getters.get_user!(params.user_id)
      true -> nil
    end

    variables = if user do
      Map.merge(variables, %{
        user: user, 
        user_name: user.name, 
        user_mail: user.email,
        usexe: user.sexe # "H" ou "F"
      })
    else variables end
    # - Procédure -
    variables = if Map.get(params, :procedure) do
      Map.merge(variables, %{
        proc_url: [Constantes.get(:app_url), "proc", params.procedure.id] |> Enum.join("/")
      })
    else variables end

    Map.put(params, :variables, variables)
  end

  @doc """
  Pour enregistrer une notification

  Cette notification, suivant le destinataire (target), apparaitra
  sur le bureau d'administration ou le bureau du membre/user
  """
  def notify(params) do
    create_notification(params)
    :ok
  end

  def philhtml_options(options \\ []) do
    options ++ [
      no_header: true, 
      evaluation: true, 
      no_file: true, 
      helpers: all_helpers()
    ]
  end

  def all_helpers do
    [
      LdQWeb.ViewHelpers, 
      LdQ.LinkHelpers,
      LdQ.Mails.Helpers,
      Helpers.Feminines,
      LdQ.Site.PageHelpers
    ]
  end

  @doc """
  Fonction qui s'assure que le dossier des livres existe et retourne
  """
  def ensure_books_folder do
    path = Path.join(~w(priv static uploads books))
    File.mkdir_p!(path)
    path
  end

end