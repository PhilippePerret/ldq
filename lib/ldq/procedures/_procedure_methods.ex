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
  Pour envoyer une mail

  @param {String|Atom} sender du message (si :admin, c'est l'administration)
  @param {String|Atom} receiver du message (si :admins, à tous les administrateurs)
  @param {Map} mail_data Les données du mail dont :
  @param {String|Atom} mail_data.id Identifiant du mail à envoyer
  @param {Map} mail_data.variables Les variables pour détemplatiser le message
  """
  def send_mail(sender, receiver, params) do
    mail_path = Path.join([params.folder, "mails", "#{params.mail_id}.phil"])
    params    = defaultize_mail_params(params)
    variables = params.variables

    # On formate le mail
    phil_data = PhilHtml.to_data(mail_path, 
      [no_header: true, evaluation: false, variables: variables, helpers: [LdQ.Helpers.Feminines]])
    |> IO.inspect(label: "Phil data du mail à envoyer")

    subject = @prefix_mail_subject <> phil_data.options[:variables][:subject]

    # Fichier joint (chemin absolu valide ou NIL) 
    attached_file = params.attached_file

    sender = case sender do
      :admin -> "admin@lecture-de-qualite.fr"
      _ -> sender
    end

    receivers = case receiver do
      :admins   -> ["admins@lecture-de-qualite.fr"]
      :readers  -> ["readers@lecture-de-qualite.fr"]
      :members  -> ["members@lecture-de-qualite.fr"]
      _ -> [receiver]
    end

    receivers |> Enum.reduce(%{errors: [], sent: []}, fn receiver, coll ->
      email = Swoosh.Email.new()
      |> Swoosh.Email.to(receiver)
      |> Swoosh.Email.from(sender)
      |> Swoosh.Email.subject(subject)
      |> Swoosh.Email.html_body(phil_data.html)

      email =
      if attached_file do
        email |> Swoosh.Email.attach(attached_file)
      else email end

      # Envoie l'email
      case LdQ.Mailer.deliver(email) do
        {:ok, _} -> 
          %{coll | sent: coll.sent ++ [email]}
        {:error, reason} -> 
          %{coll | errors: coll.errors ++ [reason]}
      end
    end)
    |> IO.inspect(label: "Résultat de l'envoi")
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
  def notify(target, notify_id, params) do
    IO.puts "IL FAUT APPRENDRE À ENREGISTRER UNE NOTIFICATION"
    :ok
  end

end