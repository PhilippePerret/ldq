defmodule Phil do

  defmodule Map do

    @doc """
    S'assure de retourne une map avec seulement des clés string
    """
    def ensure_keys_string(map) when is_map(map) do
      map |> Elixir.Enum.reduce(%{}, fn {k,v}, c ->
        k = if is_binary(k), do: k, else: Elixir.Atom.to_string(k)
        Elixir.Map.put(c, k, v)
      end)
    end

    @doc """
    S'assure de retourner une map si c'est possible

    ## Examples

      iex> Phil.Map.ensure_map(%{cest: "déjà", une: "map"})
      %{cest: "déjà", une: "map"}

      iex> Phil.Map.ensure_map([cest: "pas encore", une: "Map"])
      %{cest: "pas encore", une: "Map"}

    """
    def ensure_map(foo) when is_list(foo) do
      Phil.Keyword.to_map(foo)
    end
    def ensure_map(foo) when is_map(foo), do: foo
    # def ensure_map(foo), do: foo

  end #/module Map

  defmodule Keyword do

    @doc """
    Tranforme un Keyword en Map

    ## Examples

      iex> Phil.Keyword.to_map([un: "keyword", nota: "Map"])
      %{un: "keyword", nota: "Map"}

    """
    def to_map(kw) when is_list(kw) do
      Elixir.Enum.reduce(kw, %{}, fn {k, v}, c ->
        Elixir.Map.put(c, k, v)
      end)
    end

  end #/module Keyword

end