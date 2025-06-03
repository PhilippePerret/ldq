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



  defmodule PFile do
    @moduledoc """
    Module de méthodes pratiques pour les fichiers
    """

    @doc """
    Pour lire les +x+ dernières lignes d'un fichier sans le lire 
    complètement, pas même en streaming.

    @param {String}  path Chemin d'accès au fichier, qui doit exister
    @param {Integer} x Le nombre de lignes à retourner
    @param {Keyword} options Les options. Peut définir :
      :line_length    {Integer} La longueur d'une ligne (moyenne) (défaut : 500)

    """
    def last_lines!(path, x, options \\ [line_length: 500]) do
      line_length = options[:line_length] || 500
      {:ok, fd} = :file.open(path, [:read, :binary])
      {:ok, fileinfo} = :file.read_file_info(fd)
      size = elem(fileinfo, 1)
      start = max(size - (x + 10) * line_length, 0)
      :file.position(fd, start)
      {:ok, data} = :file.read(fd, size - start)
      data |> to_string() |> String.trim() |> String.split("\n") |> Enum.take(-x)
    end

    def last_lines(path, x, options \\ []) do
      try do
        {:ok, last_lines!(path, x, options)}
      rescue
        error -> {:error, error}
      end
    end

  end #/module PFile

end