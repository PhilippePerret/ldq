defmodule Feature.LogTestMethods do

  alias LdQ.Repo
  import Ecto.Query

  @doc """
  Voir le détail dans feature_methods/_main_.ex

  @usage
    res = check_activities(params)
    assert(is_nil(res), res)

  @return {Nil} En cas de succès ou {String} le message d'erreur
  """ 
  def check_activities(params) do
    res = check_logs_against(params)
    # |> IO.inspect(label: "\nRÉSULTATS GÉNÉRAUX DU CHECK DES LOGS")
    nombre_expected = Keyword.get(params, :count, nil)
    cond do
    is_nil(nombre_expected) and Enum.count(res.bons) > 0 ->
      nil # ok
    nombre_expected && Enum.count(res.bons) != nombre_expected ->
      "Bad activity count: expected: #{nombre_expected}, actual: #{Enum.count(res.bons)}\n#{formate_activity_errors(res.bads)}" 
      # (si modifié => changer les tests)
    nombre_expected && Enum.count(res.bons) == nombre_expected ->
      nil # ok
    true ->
      # Erreur
      formate_activity_errors(res.bads)
    end
  end

  defp formate_activity_errors(bads) do
    bads
    |> Enum.map(fn {log, raison} ->
      "# Bad activity ##{log.id}: #{raison}"
    end)
    |> Enum.join("\n")
end

  # On relève les logs dont on a besoin
  # Pour les rapports d'erreur
  def check_logs_against(params) do
    logs = 
      Repo.all(LdQ.Site.Log)
      |> Repo.preload(:creator)
    
    nombre = Keyword.get(params, :count, 1)

    res = %{bons: logs, bads: [], error: nil}

    if Enum.count(logs) == 0 and nombre > 0 do
      # Aucun log enregistré
      %{res | error: "Aucun log enregistré."}
    else
      res = %{bons: logs, bads: []}
      |> get_logs_after(params)
      |> get_logs_public(params)
      |> get_logs_with_owner(params)
      |> get_logs_with_creator(params)
      |> get_logs_with_content(params)
    end
  end

  defp get_logs_after(res, params) do
    if Keyword.has_key?(params, :after) do
      condition = fn log -> NaiveDateTime.after?(log.inserted_at, params[:after]) end
      get_logs_with_cond(res, condition, "émis avant la date recherchée (expected: #{params[:after]}, actual: \#{log.inserted_at})")
    else res end
  end

  defp get_logs_public(res, params) do
    if Keyword.has_key?(params, :public) do
      expected_value = params[:public]
      condition = fn log -> log.public === expected_value end
      error_msg = if expected_value, do: "n'est pas public", else: "est public"
      get_logs_with_cond(res, condition, error_msg)
    else res end
  end

  defp get_logs_with_owner(res, params) do
    if Keyword.has_key?(params, :owner) do
      condition = fn log -> log.owner_id == params[:owner].id end
      get_logs_with_cond(res, condition, "pas le bon propriétaire (actual: \#{log.owner_id}, expected: #{params[:owner].id})")
    else res end
  end

  defp get_logs_with_creator(res, params) do
    if Keyword.has_key?(params, :creator) do
      condition = fn log -> log.created_by == params[:creator].id end
      get_logs_with_cond(res, condition, "pas le bon créateur (actual: \#{log.created_by}, expected: #{params[:creator].id})")
    else res end
  end

  defp get_logs_with_content(res, params) do
    if Keyword.has_key?(params, :content) do
      condition = fn log -> log.text =~ params[:content] end
      get_logs_with_cond(res, condition, "ne contient pas #{inspect params[:content]} (contient: \#{log.text})")
    else res end
  end


  defp get_logs_with_cond(res, condition, msg_err) do
    bons = res.bons
    res = %{res | bons: []}
    bons
    |> Enum.reduce(res, fn log, res -> 
      if condition.(log) do
        %{res | bons: res.bons ++ [log]}
      else
        {fmessage, _bind} = Code.eval_string("\"#{msg_err}\"", [log: log])
        %{res | bads: res.bads ++ [{log, fmessage}]}
      end
    end)
  end

end