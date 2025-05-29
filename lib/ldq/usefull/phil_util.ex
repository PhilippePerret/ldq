defmodule Phil do

  defmodule Map do

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