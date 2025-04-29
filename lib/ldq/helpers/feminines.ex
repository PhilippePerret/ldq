defmodule Helpers.Feminines do
  @moduledoc """
  Module qui permet de gérer les féminines dans les textes. 
  Elles sont définies par <: fem(:<id>, sexe) :> par exemple :
  Ch<: fem(:ere, sexe) :>
  """

  @fem_ids [
    :e,               # sorti[e]  / sorti[]
    :ere,             # premi[er] / premi[ère]    ch[ère]/ch[er]
    :eau,             # nouv[eau] /nouv[elle]   b[eau]/b[elle]
    :rice             # lect[rice]/lect[eur]
  ]

  @doc """
  Pour pouvoir ajouter les féminines à une table de variables
    variables = Helpers.Feminines.add_to(variables)
  @param {Map} variables La table des variables déjà définies
  @param {String} sexe "H" ou "F" pour homme ou femme
  """
  def add_to(variables, sexe) do
    Map.merge(variables, as_map(sexe))
  end

  @doc """
  Pour pouvoir facilement utiliser les féminines en variables, on
  peut ajouter toutes les féminines en Map. Donc :
    variables = Map.merge(variables, Helpers.Feminines.as_map(sexe))
  """
  def as_map(sexe) do
    @fem_ids
    |> Enum.reduce(%{}, fn fem_id, map -> 
      f_id = "f_#{fem_id}" |> String.to_atom
      Map.put(map, f_id, fem(fem_id, sexe))
    end)
  end

  def as_keyword(sexe) do
    @fem_ids
    |> Enum.map(fn fem_id -> 
      f_id = "f_#{fem_id}" |> String.to_atom
      {f_id, fem(fem_id, sexe)} 
    end)
  end


  def fem(fem_id, sexe) when is_atom(fem_id) do
    fem(Atom.to_string(fem_id), sexe)
  end
  def fem(fem_id, sexe) when is_map(sexe) do
    fem(fem_id, sexe.sexe)
  end
  def fem(suffix, user) when is_struct(user, LdQ.Comptes.User) do
    fem(suffix, user.sexe)
  end


  def fem("e", "F") , do: "e" # venu[e]/venu
  def fem("e", _)   , do: ""

  def fem("eau", "F") , do: "elle" # nouv[eau]/nouv[elle]
  def fem("eau", _)   , do: "eau"

  def fem("ere", "F"),  do: "ère" # Ch[er]/Ch[ère]
  def fem("ere", _),    do: "er"

  def fem("chere", "F"), do: "Chère"
  def fem("chere", _), do: "Cher"

  def fem("rice", "F"), do: "rice" # administrat[eur]/aministrat[rice]
  def fem("rice", _), do: "eur"

end
