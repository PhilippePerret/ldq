defmodule TestMailMethods do
  use LdQWeb.FeatureCase, async: false

  alias LdQ.Constantes
  alias LdQ.Comptes.User

  import TestHelpers # w() etc.
  import TestStringMethods # string_contains etc.

  @doc """
  Méthode qui teste que le +destinataire+ a bien reçu le message de 
  sujet +subject+ possédant le contenu +contenu+

  Principes :
    - on détruit le mail ou les mails dès qu'ils ont été trouvés

  @param {Map} destinataire -- map contenant au moins {:email, :name}
  @param {String} subject Le sujet du message
  @param {List>String} contenu Liste des portions de textes à trouver. Ça peut être du simple texte ou une expression régulière.
  """
  # Version en essayant de garder le maximume d'information sur les 
  # raisons de l'échec
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
    |> keep_only_mails_from_sender()
    |> keep_only_mails_by_identifiant()
    |> keep_only_mails_with_expected_subject()
  end

  defp keep_only_mails_after_point_test(resultat) do
    if is_nil(resultat.params.after) do resultat else
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
    if is_nil(resultat.destinataire) or Enum.empty?(keptmails) do resultat else
      resultat = %{resultat | keptmails: []}
      Enum.reduce(resultat.keptmails, resultat, fn mail, res ->
        if mail.receiver == resultat.destinataire.email do
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
        {:error, res} ->
          %{res | exclusions: res.exclusions ++ [[reason: "BAD SUBJECT: #{inspect res.errors}", mail: mail]]}
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
        {:error, res} ->
          %{res | exclusions: res.exclusions ++ [[reason: "BAD BODY: #{inspect res.errors}", mail: mail]]}
        end
      end)
    end
  end

  def user_recoit_un_mail0(destinataire, params) when (is_map(destinataire) or is_struct(destinataire, User)) and is_map(params) do
    params = defaultize_mail_params(params)
    folder = dossier_mails()


    mail_found = 
    File.ls!(folder)
    |> Enum.map(fn fname ->
      :erlang.binary_to_term(File.read!(Path.join([folder,fname])))
    end)
    |> IO.inspect(label: "TOUS LES MAILS")
    # On ne garde que les mails après le dernier point de test
    |> Enum.filter(fn mail ->
      is_nil(params.after) || NaiveDateTime.after?(mail.sent_at, params.after)
    end)
    # On ne garde que les mails reçus par le destinataire
    |> Enum.filter(fn mail -> 
      is_nil(destinataire) or (mail.receiver == destinataire.email)
    end)
    # On ne garde que les mails de l'expéditeur
    |> Enum.filter(fn mail ->
      {sender_name, sender_email} = mail.email.from
      is_nil(params.sender) or (params.sender == sender_email)
    end)
    # On ne garde que les mails du bon identifiant
    |> Enum.filter(fn mail ->
      is_nil(params.mail_id) or (params.mail_id == mail.mail_id)
    end)
    # On ne garde que les mails possédant le bon sujet
    |> Enum.filter(fn mail ->
      if is_nil(params.subject) do
        true
      else
        case string_contains(mail.subject, params.subject, params) do
        {:ok, _} = res -> true
        {:error, _} = res ->
          IO.puts Enum.join(res.errors, "\n# ")
          false
        end
      end
    end)
    # On ne garde que les mails possédant le bon contenu
    |> Enum.filter(fn mail ->
      if is_nil(params.content) do
        true
      else
        case string_contains(mail.html_body, params.content, params) do
        {:ok, _} = res -> true
        {:error, err} = res ->
          IO.puts w("# " <> Enum.join(err.errors, "\n# "), :red)
          false
        end
      end
    end)

    if is_nil(params.count) do
      assert Enum.any?(mail_found), "Aucun mail trouvé répondant aux paramètres : #{inspect params})"
    else
      s = if params.count > 1, do: "s", else: ""
      nombre_found = Enum.count(mail_found)
      err_mess = "On devait trouver #{params.count} mail#{s}, on en a trouver #{nombre_found} avec les paramètres #{inspect params}."
      assert nombre_found == params.count, err_mess
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