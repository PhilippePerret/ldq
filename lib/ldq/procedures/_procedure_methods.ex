defmodule LdQ.ProcedureMethods do
  @moduledoc """
  Gestion des procédures
  """

  import Ecto.Query, warn: false
  alias LdQ.{Repo, Comptes, Notification, Constantes, Procedure}

  @prefix_mail_subject "[📚 LdQ] "

  @doc """
  Crée la procédure avec les attributs voulus
  """
  def create_procedure(attrs) do
    %Procedure{}
    |> Procedure.changeset(attrs)
    |> Repo.insert!()
  end

  def get_procedure(proc_id) do
    Repo.get!(Procedure, proc_id)
  end

  def update_procedure(%Procedure{} = proc, attrs) do
    proc
    |> Procedure.changeset(attrs)
    |> Repo.update()
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
  def send_mail(sender, receiver, params) do

    data_mail = compose_mail(sender, receiver, params)

    data_mail.receivers |> Enum.reduce(%{errors: [], sent: []}, fn receiver, coll ->

      # Sujet propre
      subject = PhilHtml.Evaluator.customize!(data_mail.subject, data_mail.philhtml)
      # Contenu propre
      html_body = PhilHtml.Evaluator.customize!(data_mail.html_body, data_mail.philhtml)
      
      receiver = case is_binary(receiver) do
        true  -> %{name: "", email: receiver}
        false -> receiver
      end

      email = data_mail.email 
      |> Swoosh.Email.to({receiver.name, receiver.email})
      |> Swoosh.Email.subject(subject)
      |> Swoosh.Email.html_body(html_body)

      if Mix.env() == :test do
        data_mail = Map.merge(data_mail, %{
          receiver: receiver
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
    |> IO.inspect(label: "Résultat de l'envoi")
  end


  defp compose_mail(sender, receiver, params) do
    mail_path = Path.join([params.folder, "mails", "#{params.mail_id}.phil"])
    params    = defaultize_mail_params(params)
    variables = params.variables

    # On formate le mail
    phil_data = PhilHtml.to_data(mail_path, 
      [no_header: true, evaluation: false, variables: variables, helpers: [LdQ.Helpers.Feminines]])
    # |> IO.inspect(label: "Phil data du mail à envoyer")

    subject = @prefix_mail_subject <> phil_data.options[:variables][:subject]

    # Fichier joint (chemin absolu valide ou NIL) 
    attached_file = params.attached_file

    sender = case sender do
      :admin -> %{name: "Administrateur", email: "admin@lecture-de-qualite.fr", sexe: "H"}
      _ -> 
        case is_binary(sender) do
        true -> %{name: "", email: sender}
        false -> sender
        end
    end

    receivers = case receiver do
      :admins   -> [%{name: "Administrateurs", email: "admins@lecture-de-qualite.fr", sexe: "H"}]
      :readers   -> [%{name: "Lecteurs", email: "readers@lecture-de-qualite.fr", sexe: "H"}]
      :members   -> [%{name: "Membres du comité", email: "members@lecture-de-qualite.fr", sexe: "H"}]
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
      mail_id:    params.mail_id,
      receivers:  receivers,
      subject:    subject,
      html_body:  phil_data.heex,
      philhtml:   phil_data
    }
  end

  defp defaultize_mail_params(params) do
    file = Map.get(params, :attached_file, nil)

    params = params
    |> Map.put(:attached_file, file)
    |> add_common_mail_variables()
  end

  defp add_common_mail_variables(params) do
    variables = Map.get(params, :variables, [])

    variables = Keyword.merge(variables, [
      ldq_logo: "[LE LOGO DU LABEL]",
      ldq_label: ~s(<span class="label">Label de Qualité</span>)
    ])
    # - Utilisateur -
    user = cond do
      Map.get(params, :user) -> params.user
      Map.get(params, :user_id) ->
        Comptes.get_user!(params.user_id)
      true -> nil
    end

    variables = if user do
      Keyword.merge(variables, [
        user: user, 
        user_name: user.name, 
        user_mail: user.email,
        usexe: user.sexe # "H" ou "F"
      ])
    else variables end
    # - Procédure -
    variables = if Map.get(params, :procedure) do
      Keyword.merge(variables, [
        proc_url: [Constantes.get(:app_url), "proc", params.procedure.id] |> Enum.join("/")
      ])
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

end