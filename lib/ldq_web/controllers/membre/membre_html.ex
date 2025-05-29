defmodule LdQWeb.MembreHTML do
  use LdQWeb, :html

  alias LdQ.Comptes.User

  embed_templates "membre_html/*"

  def modules(membre) do
    modules = 
    [
      nouveaux_livres: "C1",
      membre_en_chiffres: "C3",
      evaluations: "C2"
    ] |> Enum.map(fn {module_id, position} -> 
      methode = String.to_atom("module_#{module_id}")
      apply(__MODULE__, methode, [membre])
    end)
    |> Enum.join("")


  end

  # MODULE
  # Retourne le module qui permet au membre de trouver les livres 
  # qu'il a en lecture (en évaluation)
  def module_evaluations(membre) do
    """
    <h4>Évaluations en cours</h4>
    <p class="error">[Le membre trouvera ici la liste des livres qu'il a en évaluation]</p>
    """
  end

  # MODULE
  # Retourne le module qui permet au membre de voir les nouveaux 
  # livres à évaluer
  def module_nouveaux_livres(membre) do
    # Relever la liste des nouveaux livres correspondant au niveau
    # du membre
    new_books = Book.get_not_evaluated(membre.college)

    """
    <h4>Liste des nouveaux livres</h4>
    <p class="explication">Trouvez ci-dessous la liste des nouveaux livres à choisir</p>
    """
  end

  # MODULE
  # Retourne la carte du membre en chiffre, crédit, livres lus, etc.
  def module_membre_en_chiffres(membre) do
    rows_cars = [
      credit: "Crédit",
      book_count: "Livres lus",
      anciennete: "Ancienneté"
    ]
      |> Enum.map(fn {prop, title} ->
        value = Map.get(membre, prop, "---")
        "<tr><td>#{title}</td><td>#{value}</td></tr>"
      end)
      |> Enum.join()
    
    """
    <h4>Vos caractéristiques</h4>
    <table>#{rows_cars}</table>
    """
  end
end