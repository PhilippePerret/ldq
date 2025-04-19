defmodule LdQ.Book.Genre do
  use Ecto.Type
  @moduledoc """
  Module pour la gestion des genres d'histoire
  """

  @genres %{
    "lit-gen"   => "Littérature générale", 
    "enfants"   => "Livre pour enfants",
    "youngadul" => "Littérature pour jeunes adultes",
    "fantasy"   => "Fantaisie",
    "romance"   => "Romance",
    "aventur"   => "Roman d'aventure",
    "contes"    => "Conte & légende",
    "drame"     => "Drame", 
    "polar"     => "Polar", 
    "thriller"  => "Thriller",
    "policier"  => "Policier",
    "investi"   => "Roman d'investigation",
    "historic"  => "Historique (non autorisé)",
    "docu"      => "Documentaire (non autorisé)",
    "poesie"    => "Poésie (non autorisé)"
  }

  def type, do: :string

  def cast(value) when is_binary(value) do
    if Map.has_key?(@genres, value), do: {:ok, value}, else: :error
  end
  def cast(_), do: :error

  def dump(value), do: cast(value)
  def load(value), do: cast(value)

  # Pour les select
  def values, do: Enum.map(@genres, fn {k, v} -> {v, k} end)
    
end