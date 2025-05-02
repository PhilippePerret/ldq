defmodule LdQ.ProcedureMethods do
  @moduledoc """
  Gestion des procédures
  """

  import Ecto.Query, warn: false
  alias LdQ.{Repo, Comptes, Notification, Constantes, Procedure}
  alias LdQ.Comptes.User


  @prefix_mail_subject "[📚 LdQ] "


  def __run__(module, procedure) do
    run_current_procedure(procedure, module, module.steps())
  end

  @doc """
  Retourne le texte contenu dans le fichier spécifié, après l'avoir
  interprété en PhilHtml (s'il a besoin d'être actualisé)

  Le fichier doit obligatoirement se trouver dans un dossier "textes"
  de la procédure.

  Note : les helpers sont transmis, à savoir : 
    Helpers.Feminines
    LdQWeb.ViewHelpers

  @param {String} folder Le dossier de la procédure (__DIR__)
  @param {String} root_name Le nom racine du fichier
  @param {Keyword} vars Liste des variables à utiliser
                    Si :user est renseigné, la fonction ajoute automatiquement les variables user_name, user_mail et user_id
  """
  def load_phil_text(folder, root_name, vars \\ %{}) do
    path = Path.join([folder, "textes", "#{root_name}.phil"])
    vars = 
      if Map.has_key?(vars, :user) do
        vars
        |> Map.merge(Helpers.Feminines.as_map(vars.user.sexe))
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
  Pour enregistrer une activité
  @param {Map} params Les paramètres requis par %LdQ.Site.Log{}. Cf. lib/site/log.ex
  """
  def log_activity(params) do
    case LdQ.Site.Log.create(params) do
    {:ok, changeset} -> true
    {:error, changeset} -> 
      # TODO Prévenir l'administration du site
      false
    end
  end

  @doc """
  Pour vérifier si l'utilisateur courant est abilité à jouer la
  procédure voulu (donc son next_step)

  @return True si l'utilisateur courant est autorisé, False dans le
  cas contraire
  """
  def current_user_can_run_step?(curuser, procedure) do
    steps = LdQ.Procedure.get_steps_of(procedure)
    step  = current_procedure(procedure, steps)
    owner = get_owner(procedure)

    admin_validity = !step.admin_required || User.admin?(curuser)
    owner_validity = !step.owner_required || (curuser.id == owner.id)

    admin_validity && owner_validity
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
    Enum.find(steps, fn step ->
      step.fun == procedure.next_step |> String.to_atom()
    end)
  end

  def run_current_procedure(procedure, module, steps) do
    step = current_procedure(procedure, steps)
    apply(module, step.fun, [procedure])
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
      Comptes.get_user!(user_id)
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
  Crée la procédure avec les attributs voulus
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
      param[:dim]   {String} Le proc_dim de la procédure
      param[:after] {NaiveDateTime} La procédure doit avoir été créée après cette date
  @return %{List of Map} Liste des procédures répondant aux paramètres +params+
  """
  def get_procedure(params) when is_list(params) do
    # - Défaultize params -
    params = 
      if Keyword.has_key?(:dim) do
        Keyword.put(params, :proc_dim, params[:dim])
      else params end
    # - Build request -
    query = from(p in Procedure)
    query = 
      if Keyword.has_key?(params, :owner) do
        where(query, [p], p.owner_id == ^params[:owner].id)
      else query end
    query =
      if Keyword.has_key?(param, :proc_dim) do
        where(query, [p], p.proc_id == ^params[:proc_dim])
      else query end
    query = 
      if Keyword.has_key?(param, :after) do
        where(query, [p], NaiveDateTime.after?(p.inserted_at, ^params[:after]))
      else query end
    Repo.get_all(query)
    |> Repo.preload(:creator)
  end
  def get_procedure(proc_id) do
    Repo.get!(Procedure, proc_id)
  end

  def update_procedure(%Procedure{} = proc, attrs) do
    proc
    |> Procedure.changeset(attrs)
    |> Repo.update!()
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
  En mode test, au lieu d'envoyer le mail, on l'enregistre dans un 
  fichier avec sa date d'envoi.
  """
  def consigne_mail_for_test(data_mail) do
    path = Path.join(["test","xtmp", "mails_sent", "#{Ecto.UUID.generate()}"])
    data_mail = Map.merge(data_mail, %{
      sent_at: NaiveDateTime.utc_now()
    })
    # Pour le moment, pour ne pas alourdir, on retire l'objet PhilHtml
    data_mail = Map.delete(data_mail, :philhtml)
    data_string = :erlang.term_to_binary(data_mail)
    File.write!(path, data_string)
  end

  @doc """
  Pour envoyer un mail

  @param {String|Atom} sender du message (si :admin, c'est l'administration)
  @param {String|Atom|User|Array>Users} receiver du message (si :admins, à tous les administrateurs)
  @param {Map} mail_data Les données du mail dont :
  @param {String|Atom} mail_data.id Identifiant du mail à envoyer
  @param {Map} mail_data.variables Les variables pour détemplatiser le message
  """
  def send_mail([to: receiver, from: sender, with: params] = attrs) do
    send_mail(receiver, sender, params)
  end
  def send_mail(receiver, sender, params) do

    data_mail = compose_mail(sender, receiver, params)

    # Il faut modifier les propriétés de data_mail.philhtml pour que
    # l'évaluation soit demandée
    philhtml = data_mail.philhtml
    philhtml = %{philhtml | options: Keyword.put(philhtml.options, :evaluation, true)}
    data_mail = %{data_mail | philhtml: philhtml}

    data_mail.receivers 
    |> Enum.reduce(%{errors: [], sent: []}, fn receiver, coll ->

      receiver = case is_binary(receiver) do
        true  -> %{name: "", email: receiver, sexe: "H"}
        false -> receiver
      end

      # Sujet propre
      subject = PhilHtml.Evaluator.customize!(data_mail.subject, data_mail.philhtml)
      # Contenu propre
      # --------------
      # Il faut ajouter les variables féminines pour le receveur 
      # courant. Le problème actuel est que :receiver, ici, contient
      # au mieux :name et :mail.
      opts = data_mail.philhtml.options
      opts = 
        opts
        |> Keyword.put(:variables, Helpers.Feminines.add_to(opts[:variables], receiver.sexe) )
      philhtml = %{data_mail.philhtml | options: opts}
      html_body = PhilHtml.Evaluator.customize!(data_mail.heex_body, philhtml)
      
      # IO.inspect(subject, label: "\n+++ SUJET PROPRE")
      # IO.inspect(html_body, label: "\n+++ CONTENU PROPRE")


      email = data_mail.email 
      |> Swoosh.Email.to({receiver.name, receiver.email})
      |> Swoosh.Email.subject(subject)
      |> Swoosh.Email.html_body(html_body)

      if Mix.env() == :test do
        # Mode test : consigner les données du mail

        data_mail = Map.merge(data_mail, %{
          receiver: receiver,
          subject:  subject,
          html_body: html_body
        })
        consigne_mail_for_test(data_mail)
      else
        # Envoi de l'email
        case LdQ.Mailer.deliver(email) do
          {:ok, _} -> 
            %{coll | sent: coll.sent ++ [email]}
          {:error, reason} -> 
            %{coll | errors: coll.errors ++ [reason]}
        end
      end
    end)
    # |> IO.inspect(label: "Résultat de l'envoi")
  end


  defp compose_mail(sender, receiver, params) do
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
        helpers: [LdQ.Mails.Helpers, Helpers.Feminines, LdQWeb.ViewHelpers]
      ])
    # |> IO.inspect(label: "\n\n+++ PHILDATA DU MAIL À ENVOYER")

    subject = @prefix_mail_subject <> (phil_data.options[:variables].subject || "(Sans objet)")

    # Fichier joint (chemin absolu valide ou NIL) 
    attached_file = params.attached_file

    sender = case sender do
      :admin    -> %{name: "Administrateur", email: "admin@lecture-de-qualite.fr", sexe: "H"}
      :member   -> %{name: "Membre du comité", email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}
      :membre   -> %{name: "Membre du comité", email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}
      :members  -> %{name: "Membre du comité", email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}
      :membres  -> %{name: "Membre du comité", email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}
      _ -> 
        case is_binary(sender) do
        true -> %{name: "", email: sender, sexe: "H"}
        false -> sender
        end
    end

    receivers = case receiver do
      :admins   -> [%{name: "Administrateurs", email: "admin@lecture-de-qualite.fr", sexe: "H"}]
      :admin    -> [%{name: "Administrateur", email: "admin@lecture-de-qualite.fr", sexe: "H"}]
      :readers  -> [%{name: "Lecteurs", email: "readers@lecture-de-qualite.fr", sexe: "H"}]
      :members  -> [%{name: "Membres du comité", email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}]
      :membres  -> [%{name: "Membres du comité", email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}]
      _ -> [receiver]
    end

    email = Swoosh.Email.new()
    |> Swoosh.Email.from({sender.name, sender.email})
    email =
    if attached_file do
      email |> Swoosh.Email.attach(attached_file)
    else email end

    %{
      email:      email,
      procedure:  params.procedure,
      mail_id:    params.mail_id,
      receivers:  receivers,
      subject:    subject,
      heex_body:  phil_data.heex,
      philhtml:   phil_data
    }
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
        Comptes.get_user!(params.user_id)
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
      helpers: [LdQWeb.ViewHelpers]
    ]
  end

end