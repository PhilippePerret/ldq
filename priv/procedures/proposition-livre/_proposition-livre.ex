defmodule LdQ.Procedure.PropositionLivre do
  @moduledoc """
  Cette procédure commence avec la proposition d'un livre pour le
  label Lecture de Qualité jusqu'à sa mise en test.
  Donc il ne s'agit que du début de la longue procédure.
  """
  import LdQ.ProcedureMethods
  use Phoenix.Component

  @steps [
    %{name: "Proposition du livre", fun: proposition_livre},
    %{name: "Consignation du livre", fun: consigne}
  ]
  def steps, do: @steps


  @doc """
  Fonction appelée pour permettre à l'utilisateur de proposer un
  livre au label. Elle lui affiche le formulaire à remplir.
  """
  def proposition_livre(procedure) do
    """
    <form action="/proc/#{procedure.id}?nstep=consigne" method="POST">
      #{token_field()}
    
    </form>
    """
  end

  def consigne(procedure) do
    book = procedure.params["book"]
    |> IO.inspect(label: "Paramètres du livre")

    # TODO Avertir l'administration

    # TODO Confirmation à l'auteur que le livre a bien été enregistré

    """
    <p>Merci pour cette proposition de livre.</p>
    <p>Voilà ce qui va se passer ensuite :</p>
    <ul>
    </ul>
    """
  end
end