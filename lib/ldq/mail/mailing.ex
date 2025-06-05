defmodule LdQ.Mailing do
  @moduledoc """

  Pour gérer les envois en masse sans se faire traiter de spammer.

  Exemple de campagne avec Brevo (https://app.brevo.com) :
  (https://app.brevo.com/settings/keys/api)

  Note : les informations sont enregistrées dans un fichier secret

    # ------------------
    # Create a campaign
    # ------------------
    curl -H 'api-key: YOUR_API_V3_KEY'
    -X POST -d '{
    # Define the campaign settings
    "name":"Campaign sent via the API",
    "subject":"My subject",
    "sender": {"name":"From name", "email":"myfromemail@mycompany.com" },
    "type":"classic",
    # Content that will be sent
    "htmlContent":"Congratulations! You successfully sent this example campaign via the Brevo API.",
    # Select the recipients
    "recipients": { "listIds": [2,7] },
    # Schedule the sending in one hour
    "scheduledAt": "2018-01-01 00:00:01",
    }'
    'https://api.brevo.com/v3/emailCampaigns'

  """


  @doc """
  Pour faire un mailing (pour le moment par Brevo) avec les 
  paramètres transmis.

  @param {Map} params Table des données
    params.name:          {String} Le nom du mailing
    params.schedule_at:   {DateTime} Date d'envoi dans le futur
    params.recipients:    {List} Liste des destinataires (par id nombre sur Brevo)
    params.subject:       {String} Le sujet du mailing
    params.body:          {HTMLString} Le corps HTML du message à envoyer
  """
  def send_mailing(_params) do
    # Peut-être qu'il faut récupérer les identifiants des 
    # destinataires pour faire la liste des identifiants
    # OU : utiliser les segments de liste pour faciliter le travail
    if true do # TODO: mettre mode test
      IO.puts "Mailing en mode TEST"
    else
      IO.puts "Mailing en mode NORMAL (DÉV ET PROD)"
    end
  end

end