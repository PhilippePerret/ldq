defmodule LdQ.Comptes.Membre do
  @moduledoc """
  Module du membre de comité de lecture LdQ
  """
  defstruct [:id, :name, :sexe, :email, :privileges, :member_card, :member_card_id, :book_count, :credit, :college]

  alias LdQ.Evaluation.Numbers, as: Calc

  @doc """
  Fonction qui permet d'ajouter des propriétés au membre pour le
  manipuler plus facilement.
  Elle est appelée automatiquement par la fonction : 
    get_user_as_membre!(id|user)
  """
  def add_props(membre) do
    # Le collège
    college = 
      cond do
        is_nil(membre.credit) -> 1
        membre.credit < Calc.points_for(:seuil_college_two)   -> 1
        membre.credit < Calc.points_for(:seuil_college_three) -> 2
        true -> 3
      end
    membre = %{membre | college: college}

    membre
  end
end