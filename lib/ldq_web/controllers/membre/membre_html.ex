defmodule LdQWeb.MembreHTML do
  use LdQWeb, :html

  alias LdQ.Comptes.User
  alias LdQ.Library.Book
  alias LdQ.Evaluation.CreditCalculator, as: Calc

  embed_templates "membre_html/*"

  def modules(membre) do
    modules = 
    [
      nouveaux_livres: "C1",
      membre_en_chiffres: "C3",
      evaluations: "C2"
    ] |> Enum.map(fn {module_id, position} -> 
      # IO.puts "Construction du module #{module_id}"
      methode = String.to_atom("module_#{module_id}")
      apply(__MODULE__, methode, [membre])
    end)
    |> Enum.join("")


  end

  # MODULE
  # Retourne le module qui permet au membre de trouver les livres 
  # qu'il a en lecture (en évaluation)
  def module_evaluations(membre) do
    # Les livres en évaluation. Ce sont :
    #   - les livres pour lesquels le membre possède une fiche BookUser
    #   - dont la note n'a pas encore été affectée (donc valeur nil)
    evaluated_books = 
      Book.get_books_evaluated_by(membre, type: :current)
      |> Enum.map(fn book -> 
        """
        <div class="book">
          <div class="title">
            <span class=picto-book>📕</span>
              #{book.title} 
              <span class=author>(#{book.author.name})</span>
          </div>
          <div class=buttons>
            <a href="">Attribuer une note</a>
          </div>
        </div>
        """
      end)
      |> Enum.join("")
    """
    <h4>Évaluations en cours</h4>
    <p class="error">[Le membre trouvera ici la liste des livres qu'il a en évaluation]</p>
    <section id="evalued-books">
    #{evaluated_books}
    </section>
    """
  end

  # MODULE
  # Retourne le module qui permet au membre de voir les nouveaux 
  # livres à évaluer
  def module_nouveaux_livres(membre) do
    # Relever la liste des nouveaux livres correspondant au niveau
    # du membre
    key_points = String.to_atom("book_evaluation_college#{membre.college}")
    pts_evaluation = Calc.points_for(key_points)
    new_books = Book.get_not_evaluated(membre.college, by: membre)

    section_new_books = 
    if Enum.count(new_books) > 0 do
      new_books
      |> Enum.map(fn book ->
        """
        <div class="book">
          <span class=picto-book>📙</span>
          <div class="title">#{book.title} <span class="author">(#{book.author_name})</span></div>
          <div class="buttons"><a id="btn-eval-#{book.id}" class"btn small" href="?id=#{book.id}&type=book&op=choose-for-eval">évaluer (#{pts_evaluation} crédits)</a></div>
        </div>
        """
      end)
      |> Enum.join("")
    else
      "<p class=\"italic\">Aucun nouveau livre à évaluer.</p>"
    end

    """
    <h4>Nouveaux livres à évaluer</h4>
    <p class="explication">Trouvez ci-dessous la liste des nouveaux livres à choisir</p>
    <section id="new-books">
    #{section_new_books}
    </section>
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