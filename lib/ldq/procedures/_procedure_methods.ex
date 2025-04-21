defmodule LdQ.Procedure do
  @moduledoc """
  Gestion des procédures
  """

  import Ecto.Query, warn: false
  alias LdQ.{Repo, Comptes, Notification, Constantes}

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
  def send_mail(receiver, sender, params) do
    mail_path = Path.join([params.folder, "mails", params.mail_id])
    variables = add_common_mail_variables(params)
    phil_data = PhilHtml.to_phil(mail_path, [no_header: true, variables: variables])
    |> IO.inspect(label: "Phil data du mail à envoyer")
    subject = phil_data.variables["subject"]

    IO.puts "IL FAUT APPRENDRE À ENVOYER UN MAIL"
    # TODO récupérer le mail
    # TODO Détemplatiser le mail
    # TODO Envoyer le mail à tous les destinataires
  end

  defp add_common_mail_variables(params) do
    variables = params.variables || %{}
    # - Utilisateur -
    variables = if Map.get(params, :user_id) do
      user = Comptes.get_user!(params.user_id)
      Map.merge(variables, %{user_name: user.name, user_mail: user.mail})
    else variables end
    # - Procédure -
    variables = if Map.get(params, :procedure) do
      Map.merge(variables, %{
        proc_url = [Constantes.get(:app_url), "proc", procedure.id] |> Enum.join("/")
      })
    else variables end
  end

  @doc """
  Pour enregistrer une notification

  Cette notification, suivant le destinataire (target), apparaitra
  sur le bureau d'administration ou le bureau du membre/user
  """
  def notify(target, notify_id, params) do
    IO.puts "IL FAUT APPRENDRE À ENREGISTRER UNE NOTIFICATION"
  end

end