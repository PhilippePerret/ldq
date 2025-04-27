defmodule TestStringMethods do
  @moduledoc """
  Module contenant les méthodes de test des strings
  """


  @doc """
  Teste la présente d'une chaine, d'une expression régulière ou d'une
  liste de tout ça dans une chaine.

  @param {Map} Pour définir des options
  @param {Boolean} options.strict   En mode strict, les pure chaines doivent être intégralement bonnes
                                    False par défaut.
  """
  def string_contains(sujet, expect, options \\ %{})

  def string_contains(sujet, expect, options) when is_binary(expect) do
    case sujet == expect do
      true -> 
        {:ok, nil}
      false ->
        if Map.get(options, :strict, false) do
          {:error, %{error: "ne contient pas #{inspect expect}"}}
        else
          string_contains(sujet, ~r/#{expect}/i, options)
        end
    end
  end
  def string_contains(sujet, rexpect, _options) when is_struct(rexpect, Regex) do
    case Regex.match?(rexpect, sujet) do
      false -> {:error, %{error: "ne contient pas #{inspect rexpect}"}}
      _ -> {:ok, nil}
    end
  end
  def string_contains(sujet, expects, options) when is_list(expects) do
    resultat = 
    Enum.reduce(expects, %{in: [], out: [], errors: []}, fn expect, coll -> 
      case string_contains(sujet, expect, options) do
      {:ok, _} -> 
        Map.merge(coll, %{in: coll.in ++ [expect]})
      {:error, _res} -> Map.merge(coll, %{
        out: coll.out ++ [expect],
        errors: coll.errors ++ ["ne contient pas #{inspect expect}"]
        })
      end
    end)
    if Enum.any?(resultat.out) do
      {:error, resultat}
    else
      {:ok, resultat}
    end
  end

end