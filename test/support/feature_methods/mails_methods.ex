defmodule Feature.MailTestMethods do
  use LdQWeb.FeatureCase, async: false

  alias LdQ.Constantes
  alias LdQ.Comptes.User

  import TestHelpers # w() etc.
  import TestStringMethods # string_contains etc.
  import FeaturePublicMethods # Méthodes je_rejoins, etc.

  @doc """
  Méthode qui teste que le +destinataire+ a bien reçu le message de 
  sujet +subject+ possédant le contenu +contenu+

  Principes :
    - on détruit le mail ou les mails dès qu'ils ont été trouvés

  @param {Map} destinataire -- map contenant au moins {:email, :name}
  @param {String} subject Le sujet du message
  @param {List>String} contenu Liste des portions de textes à trouver. Ça peut être du simple texte ou une expression régulière.

  @return {destinataire, [mails trouvés]}
  """
  def user_recoit_un_mail(destinataire, params) when (is_map(destinataire) or is_struct(destinataire, User)) and is_map(params) do 
    params = defaultize_mail_params(params)
    folder = dossier_mails()

    resultat = %{
      params:       params,
      destinataire: destinataire, 
      allmails: [],
      keptmails: [], # les mails conservés
      exclusions: [], # les mails exclus
    }

    resultat = 
    # On prend tous les fichiers mails
    File.ls!(folder)
    # On les load pour retrouver les maps
    |> Enum.reduce(resultat, fn fname, res ->
      mail = :erlang.binary_to_term(File.read!(Path.join([folder,fname])))
      %{res | allmails: res.allmails ++ [mail]}
    end)
    # On ne garde que les mails après le points-test fourni (if any)
    |> keep_only_mails_after_point_test()
    |> keep_only_mails_received_by_dest()
    # |> IO.inspect(label: "\nRÉSULTAT après by-dest")
    |> keep_only_mails_from_sender()
    |> keep_only_mails_by_identifiant()
    |> keep_only_mails_with_expected_subject()
    |> keep_only_mails_with_expected_body()

    mails_found = resultat.keptmails
    nombre_mails_found = Enum.count(mails_found)
    aucun_mail_trouved = nombre_mails_found == 0

    if aucun_mail_trouved && params.count != 0 do
      w("\n\n##### PROBLÈME DE MAILS AVEC PARAMS #{inspect params}", :red)
      IO.inspect(resultat.exclusions, label: "\n##### RAISON DES EXCLUSIONS ###")
    end

    formated_error = formate_exclusions(resultat.exclusions)
    if is_nil(params.count) do
      msg_err = [IO.ANSI.red(), "Aucun mail trouvé répondant aux paramètres : \nDestinataire : #{inspect destinataire}\nParamètres attendus : #{inspect params}\n#{formated_error}", IO.ANSI.reset()]
      assert Enum.any?(mails_found), msg_err
    else
      s = if params.count > 1, do: "s", else: ""
      msg_err = [IO.ANSI.red(), "On devait trouver #{params.count} mail#{s}, on en a trouver #{nombre_mails_found} pour \nDestinataire : #{inspect destinataire}\nParamètres attendus : #{inspect params}\n#{formated_error}.", IO.ANSI.reset()]
      assert nombre_mails_found == params.count, msg_err
    end

    {destinataire, mails_found}

  end

  defp formate_exclusions(exclusions) do
    exclusions
    |> Enum.map(fn exclu ->
      """
      -------------------------------
      Raison : #{exclu[:reason]}
      destinataire : #{inspect exclu[:mail].receiver}
      Objet : #{exclu[:subject]}
      Body: #{exclu[:html_body]}
      -------------------------------
      """
    end)
    |> Enum.join("\n")
  end

  @doc """
  Prend le premier mail de la liste +mails+ reçue par le 
  +destinataires+, relève l'href du lien de titre +link_title+ et le
  visite.

  Pour l'utiliser dans une chaine de pipe, on utilise la méthode 
  publique :
    admin
    |> rejoint_le_lien_du_mail("titre du lien")

  @param {User|Map} destinataire. Le destinataire. Il faut au moins que la map contienne :email et :password pour que l'utilisateur puisse se connecter au besoin.
  @param {String} link_title Le titre du lien
  @param {Array>Map} mails Liste de tous les mails reçus.

  @return session La session initiée
  """
  def get_lien_in_mail_and_visit(destinataire, link_title, mails) do
    mail = Enum.at(mails, 0)
    body = mail.html_body
    href =
    Regex.scan(~r/<a .*href="(.+)".*>#{link_title}<\/a>/U, body)
    |> Enum.at(0)
    |> Enum.at(1)
    |> IO.inspect(label: "\nLien à atteindre")

    # L'administrateur ouvre une session
    destinataire
    |> rejoint_la_page(href)
    |> pause(1)
    |> et_voit("h2", "Identification")
    |> remplit_le_champ("Mail") |> avec(destinataire.email)
    |> remplit_le_champ("Mot de passe") |> avec(destinataire.password)
    |> pause(1)
    |> clique_le_bouton("Se connecter")

    destinataire
  end




  # ---- Sous-méthodes privées ----

  defp keep_only_mails_after_point_test(resultat) do
    if is_nil(resultat.params.after) do 
      resultat 
    else
      Enum.reduce(resultat.allmails, resultat, fn mail, res ->
        if NaiveDateTime.after?(mail.sent_at, resultat.params.after) do
          %{res | keptmails: res.keptmails ++ [mail]}
        else
          %{res | exclusions: res.exclusions ++ [[reason: "AFTER TEST POINT #{resultat.params.after}", mail: mail]]}
        end
      end)
    end
  end
  defp keep_only_mails_received_by_dest(resultat) do
    keptmails = resultat.keptmails
    if is_nil(resultat.destinataire) or Enum.empty?(keptmails) do 
      resultat 
    else
      resultat = %{resultat | keptmails: []}
      Enum.reduce(keptmails, resultat, fn mail, res ->
        if mail.receiver.email == resultat.destinataire.email do
          %{res | keptmails: res.keptmails ++ [mail]}
        else
          %{res | exclusions: res.exclusions ++ [[reason: "BAD RECEIVER (required #{resultat.destinataire.email})", mail: mail]]}
        end
      end)
    end
  end
  defp keep_only_mails_from_sender(resultat) do
    keptmails = resultat.keptmails
    if is_nil(resultat.params.sender) or Enum.empty?(keptmails) do resultat else
      resultat = %{resultat | keptmails: []}
      Enum.reduce(keptmails, resultat, fn mail, res ->
        {sender_name, sender_email} = mail.email.from
        if sender_email == resultat.params.sender do
          %{res | keptmails: res.keptmails ++ [mail]}
        else
          %{res | exclusions: res.exclusions ++ [[reason: "BAD SENDER (wanted #{resultat.params.sender})", mail: mail]]}
        end
      end)
    end
  end
  defp keep_only_mails_by_identifiant(resultat) do
    keptmails = resultat.keptmails
    if is_nil(resultat.params.mail_id) or Enum.empty?(keptmails) do resultat else
      resultat = %{resultat | keptmails: []}
      Enum.reduce(keptmails, resultat, fn mail, res ->
        if mail.mail_id == resultat.params.mail_id do
          %{res | keptmails: res.keptmails ++ [mail]}
        else
          %{res | exclusions: res.exclusions ++ [[reason: "BAD SENDER (wanted #{resultat.params.sender})", mail: mail]]}
        end
      end)
    end
  end
  defp keep_only_mails_with_expected_subject(resultat) do
    keptmails = resultat.keptmails
    if is_nil(resultat.params.subject) or Enum.empty?(keptmails) do resultat else
      resultat = %{resultat | keptmails: []}
      params = resultat.params
      Enum.reduce(keptmails, resultat, fn mail, res ->
        case string_contains(mail.subject, params.subject, params) do
        {:ok, _} ->
          %{res | keptmails: res.keptmails ++ [mail]}
        {:error, retour} ->
          %{res | exclusions: res.exclusions ++ [[reason: "BAD SUBJECT: #{inspect retour.error}", mail: mail]]}
        end
      end)
    end
  end
  defp keep_only_mails_with_expected_body(resultat) do
    keptmails = resultat.keptmails
    if is_nil(resultat.params.content) or Enum.empty?(keptmails) do resultat else
      resultat = %{resultat | keptmails: []}
      params = resultat.params
      Enum.reduce(keptmails, resultat, fn mail, res ->
        case string_contains(mail.html_body, params.content, params) do
        {:ok, _} ->
          %{res | keptmails: res.keptmails ++ [mail]}
        {:error, retour} ->
          %{res | exclusions: res.exclusions ++ [[reason: "BAD BODY: #{inspect retour.errors}", mail: mail]]}
        end
      end)
    end
  end

  def user_recoit_un_mail(who, params) when is_list(params) do
    params = Enum.reduce(params, %{}, fn {key, value}, coll ->
      Map.put(coll, key, value)
    end)
    user_recoit_un_mail(who, params)
  end
  def user_recoit_un_mail(:admin, params) do
    user_recoit_un_mail(%{name: "Administration", email: Constantes.get(:mail_admins)}, params)
  end
  def admin_recoit_un_mail(params) do
    user_recoit_un_mail(%{email: "admin@lecture-de-qualite.fr", name: "Admin"}, params)
  end

  

  def exec_delete_all_mails do
    folder = dossier_mails()
    File.rm_rf!(folder)
    File.mkdir!(folder)
  end

  defp dossier_mails do
    Path.join(["test","xtmp","mails_sent"])
  end

  # Pour simplifier et clarifier
  defp defaultize_mail_params(params) do
    Map.merge(%{
      sender: nil,
      mail_id: nil,
      after: nil,
      subject: nil,
      content: nil,
      count: nil
    }, params)
  end

end