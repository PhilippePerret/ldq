defmodule LdQ.Procedure do


  @doc """
  Pour envoyer une mail

  @param {String|Atom} sender du message (si :admin, c'est l'administration)
  @param {String|Atom} receiver du message (si :admins, à tous les administrateurs)
  @param {Map} mail_data Les données du mail dont :
  @param {String|Atom} mail_data.id Identifiant du mail à envoyer
  @param {Map} mail_data.variables Les variables pour détemplatiser le message
  """
  def send_mail(sender, receiver, mail_data) do
    IO.puts "IL FAUT APPRENDRE À ENVOYER UN MAIL"
    # TODO récupérer le mail
    # TODO Détemplatiser le mail
    # TODO Envoyer le mail à tous les destinataires
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