defmodule LdQ.Helpers.Feminines do
  @moduledoc """
  Module qui permet de gérer les féminines dans les textes. 
  Elles sont définies par <: fem(:<id>, sexe) :> par exemple :
  <: fem(:Chere, sexe) :>
  """

  def fem("rice", "F"), do: "rice" # administrat[eur]/aministrat[rice]
  def fem("eur", _), do: "eur"

  def fem("Chere", "F"), do: "Chère"
  def fem("Chere", _), do: "Cher"

end