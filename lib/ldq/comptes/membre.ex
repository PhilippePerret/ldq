defmodule LdQ.Comptes.Membre do
  defstruct [:name, :sexe, :email, :privileges, :member_card, :member_card_id, :book_count, :credit, :college]

  alias LdQ.Evaluation.CreditCalculator, as: Calc

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