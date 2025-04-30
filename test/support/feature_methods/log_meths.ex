defmodule Feature.LogTestMethods do

  alias LdQ.Repo
  import Ecto.Query

  # Voir le détail dans feature_methods/_main_.ex
  def has_activity?(params) do
    logs = get_logs_whose_match(params)
    Enum.count(logs) == Keyword.get(params, :count, 1)
  end

  # On relève les logs dont on a besoin
  defp get_logs_whose_match(params) do
    if Keyword.has_key?(params, :after) do
      from(log in LdQ.Site.Log, where: log.inserted_at < ^params[:after])
      |> Repo.all()
    else
      Repos.all(LdQ.Site.Log)
    end
    |> Repo.preload(:creator)
    |> Enum.filter(fn log ->
      if Keyword.has_key?(params, :owner) do
        log.owner.id == params.owner.id
      else true end
    end)
    |> Enum.filter(fn log ->
      if Keyword.has_key?(params, :content) do
        log.text =~ params.content
      else true end
    end)
    |> Enum.filter(fn log ->
      if Keyword.has_key?(params, :public) do
        log.public === params.public
      else true end
    end)

  end

end