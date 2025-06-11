defmodule LdQ.Mailer do
  use Swoosh.Mailer, otp_app: :ldq

  alias LdQ.Constantes

  import Swoosh.Email

  @default_mails_folder Path.absname(Path.join(["priv","gettext",Constantes.get(:lang),"mails"]))


  @doc """
  Pour envoyer un mail à partir d'un fichier .phil (définissant 
  notamment le sujet en metadonnée)

  Par exemple :

    send_mail(to: x, from: :admin, with: %{id: "mon-mail", variables: %{...}})

  @param {String|Atom} sender du message (si :admin, c'est l'administration)
  @param {String|Atom|User|Array>Users} receiver du message (si :admins, à tous les administrateurs)
  @param {Map} params Les données du mail dont :
    :mail_id    {String} L'identifiant du mail dans son dossier
    :procedure  {Procedure} La procédure générant le mail
    :folder     {String} Le dossier dans lequel trouver le dossiers mails (en général __DIR__)
                Par défaut, le dossier général des mails, dans priv/gettext
    :user       {User} l'user du mail, la cible, en général (mais pas forcément toujours le destinataire)
    :variables  {Map} Table des variables particulières
                De nombreuses variables seront ajoutées automatiquement aux mails,
                comme les féminines, les variables user (user_name, user_mail, etc.)
                Seront aussi injectée automatiquement les variables de la procédure si
                la procédure est transmise
  """
  def send_phil_mail([to: receiver, from: sender, with: params] = _attrs) do
    send_phil_mail(receiver, sender, params)
  end
  def send_phil_mail(receiver, sender, params) do

    params = defaultize(params)

    data_mail = compose_phil_mail(sender, receiver, params)

    # Il faut modifier les propriétés de data_mail.philhtml pour que
    # l'évaluation soit demandée
    philhtml  = data_mail.philhtml
    philhtml  = %{philhtml | options: Keyword.put(philhtml.options, :evaluation, true)}
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
      # courant.
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

      if Constantes.env_test? do
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


  @doc """
  Pour un envoi simple de message en fournissant tous les éléments bruts.
  """
  def send_email(params) do
    params = defaultize(params)
    new()
    |> from(params[:from])
    |> to(params[:to])
    |> subject(params[:subject])
    |> html_body(params[:body])
    |> deliver()
  end


  def send_test_email() do
    new()
    |> from("phil@atelier-icare.net")
    |> to("philippe.perret@yahoo.fr")
    |> subject("Test de l'envoi d'email")
    |> text_body("Ceci est un test pour vérifier que l'envoi fonctionne.")
    |> deliver()
    IO.puts "J'ai bien envoyé le mail"
  end


  defp defaultize(params) do

    # On ajoute toutes les clés utiles
    params = Map.merge(%{
      folder: nil
    }, params)

    # - Expéditeur -
    params =
      case params[:from] do
        :admin -> %{params | from: Constantes.get(:mail_admin)}
        _ -> params
      end
    
    # - Destinataire -
    params = 
      case params[:to] do
        :admin -> %{params | to: Constantes.get(:mail_admin)}
        _ -> params
      end

    # - Dossier contenant le mail -
    folder = params[:folder]
    real_folder = 
      cond do 
        is_nil(folder) -> 
          @default_mails_folder
        File.exists?(Path.join([folder,"mails"])) -> # pour les procédures
          Path.join([folder,"mails"])
        File.exists?(folder) -> 
          folder
        true -> 
          raise "Impossible de trouver le dossier du mail"
      end
    params = %{params | folder: real_folder}

    params
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



  # Fonction privée qui compose le mail à envoyer
  defp compose_phil_mail(sender, receiver, params) do
    {phil_data, params} = get_and_formate_mail(params)

    # Fichier joint (chemin absolu valide ou NIL) 
    attached_file = params.attached_file

    sender = case sender do
      :admin    -> %{name: "Administrateur"   , email: "admin@lecture-de-qualite.fr", sexe: "H"}
      :member   -> %{name: "Membre du comité" , email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}
      :membre   -> %{name: "Membre du comité" , email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}
      :members  -> %{name: "Membre du comité" , email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}
      :membres  -> %{name: "Membre du comité" , email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}
      _ -> 
        case is_binary(sender) do
        true -> %{name: "", email: sender, sexe: "H"}
        false -> sender
        end
    end

    receivers = 
      case receiver do
        :admins   -> [%{name: "Administrateurs", email: "admin@lecture-de-qualite.fr", sexe: "H"}]
        :admin    -> [%{name: "Administrateur", email: "admin@lecture-de-qualite.fr", sexe: "H"}]
        :readers  -> [%{name: "Lecteurs", email: "readers@lecture-de-qualite.fr", sexe: "H"}]
        :members  -> [%{name: "Membres du comité", email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}]
        :membres  -> [%{name: "Membres du comité", email: "membre-comite@lecture-de-qualite.fr", sexe: "H"}]
        _ -> [receiver]
      end
      # |> IO.inspect(label: "Receivers")

    email = Swoosh.Email.new()
    |> Swoosh.Email.from({sender.name, sender.email})
    email =
    if attached_file do
      email |> Swoosh.Email.attachment(attached_file)
    else email end

    common_data = %{
      email:      email,
      mail_id:    params.mail_id,
      receivers:  receivers,
      subject:    phil_data.subject,
      heex_body:  phil_data.heex,
      philhtml:   phil_data
    }

    common_data = if params[:procedure] do
      Map.put(common_data, :procedure, params.procedure)
    else common_data end

    common_data
  end

  # Fonction qui récupère et formate le message
  # @return {phildata, params} Avec params qui a été "augmenté"
  defp get_and_formate_mail(params) do
    mail_path = 
      [params.folder, "#{params.mail_id}.phil"] 
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
    variables = Map.get(params, :variables, %{}) |> Phil.Map.ensure_map()

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

  def all_helpers do
    [
      LdQWeb.ViewHelpers, 
      LdQ.LinkHelpers,
      LdQ.Mails.Helpers,
      Helpers.Feminines,
      LdQ.Site.PageHelpers
    ]
  end


end
