defmodule Helpers.Feminines do
  @moduledoc """
  Module qui permet de gérer les féminines dans les textes. 
  Elles sont définies par <: fem(:<id>, sexe) :> par exemple :
  <: fem(:Chere, sexe) :>
  """

  @fem_ids [
    :e, 
    :belle,
    :Chere, :chere,
    :rice
  ]

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

  def fem("belle", "F") , do: "belle" # [belle]/[beau]
  def fem("belle", _)   , do: "beau"

  def fem("Chere", "F"), do: "Chère"
  def fem("Chere", _), do: "Cher"

  def fem("chere", "F"), do: "Chère"
  def fem("chere", _), do: "Cher"

  def fem("rice", "F"), do: "rice" # administrat[eur]/aministrat[rice]
  def fem("rice", _), do: "eur"

end
