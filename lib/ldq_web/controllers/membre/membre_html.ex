defmodule LdQWeb.MembreHTML do
  use LdQWeb, :html

  # alias LdQ.Comptes.User
  alias LdQ.Library.Book
  alias LdQ.Evaluation.Numbers, as: Calc

  embed_templates "membre_html/*"

  def modules(membre) do
    [
      nouveaux_livres: "C1",
      membre_en_chiffres: "C3",
      evaluations: "C2",
      parrainages: "C4"
    ] |> Enum.map(fn {module_id, _position} -> 
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
    key_points = String.to_atom("book_evaluation_college#{membre.college}")
    pts_evaluation = Calc.points_for(key_points)
    # Les livres en évaluation. Ce sont :
    #   - les livres pour lesquels le membre possède une fiche BookUser
    #   - dont la note n'a pas encore été affectée (donc valeur nil)
    evaluated_books = 
      Book.get_books_evaluated_by(membre, type: :current)
      |> Enum.map(&book_card(&1, set_note: true, points_per_eval: pts_evaluation))
      |> Enum.join("")
    """
    <h4>Vos évaluations en cours</h4>
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
      |> Enum.map(&book_card(&1, evaluate: true, points_per_eval: pts_evaluation))
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
      "<tr><td>#{title}</td><td></td><td>#{value}</td></tr>"
    end)
    |> Enum.join()
    
    """
    <h4>Vos caractéristiques</h4>
    <table>#{rows_cars}</table>
    """
  end


  # MODULE
  # Section parrainage ou le membre du troisième collège peut voir
  # les livres qu'il parraine.
  def module_parrainages(membre) do
    if membre.college == 3 do
      build_module_parrainage(membre)
    else "" end
  end
  defp build_module_parrainage(membre) do
    parrainages = 
    Book.filter(%{parrain: membre}, [:title, :author, :id])
    |> Enum.map(&book_card(&1, [parrainage: true]))
    |> Enum.join("")
    """
    <h4>Vos parrainages</h4>
    <section id="parrainages">#{parrainages}</section>
    """
  end


  # ============ FONCTIONAL METHODS ==================

  # Construit et retourne la carte du livre (à afficher dans la 
  # section appelante)
  # 
  # @param {Book} book Le livre dont il faut faire la carte
  # @param {Keyword} options Les options à prendre en compte
  #   :evaluate   Mis à True pour pouvoir choisir un livre à évaluer
  #   :set_note   Mis à True pour pouvoir évaluer un livre (lui donner une note)
  #   :points_per_eval  {Integer} Nombre de points que vaut une évaluation du livre
  defp book_card(book, options) do
    # La nouvelle table pour définir les données propres au livre.
    dbook = Map.merge(book, %{
      buttons: [btn_book("voir", book)],
      picto:   "📕",
      points_per_eval: options[:points_per_eval]
    })
    # Définition des boutons, picto et autres données pour le livre
    dbook = if options[:evaluate] do
      boutons = [btn_book("eval", dbook)]
      Map.merge(dbook, %{
        buttons: dbook.buttons ++ boutons,
        picto:   "📗"
      })
    else dbook end
    dbook = if options[:set_note] do
      boutons = [btn_book("noter", dbook)]
      Map.merge(dbook, %{
        buttons:  dbook.buttons ++ boutons,
        picto:    "📙"
      })
    else dbook end
    dbook = if options[:parrainage] do
      boutons = [btn_book("refus", dbook)]
      Map.merge(dbook, %{
        buttons:  dbook.buttons ++ boutons,
        picto:    "📘"
      })
    else dbook end

    author_name =
      if Map.has_key?(book, :author_name) do
        book.author_name
      else
        book.author.name
      end

    """
    <div class="book">
      <div class="title">
        <span class=picto-book>#{dbook.picto}</span>
          #{book.title} 
          <span class=author>(#{author_name})</span>
      </div>
      <div class=buttons>
        #{Enum.join(dbook.buttons, "")}
      </div>
    </div>
    """
  end

  defp btn_book("voir", book) do
    small_button(
      id: "btn-voir-#{book.id}", 
      href: "/livre/#{book.id}", 
      title: "voir")
  end
  defp btn_book("eval", dbook) do
    small_button(
      id: "btn-eval-#{dbook.id}", 
      href: "?id=#{dbook.id}&type=book&op=choose-for-eval", 
      title: "évaluer (#{dbook.points_per_eval} crédits)"
    )
  end
  defp btn_book("noter", dbook) do
    small_button(
      id: "btn-noter-#{dbook.id}",
      href: "",
      title: "noter"
    )
  end
  # Bouton pour refuser un parrainage
  defp btn_book("refus", dbook) do
    small_button(
      id: "btn-refus-parrainage-#{dbook.id}",
      href: "?id=#{dbook.id}&type=book&op=refus-parrainage",
      title: "refuser",
      class: "warning"
    )
  end

  defp small_button(params) do
    cls = params[:class] || []
    cls = if is_binary(cls), do: [cls], else: cls
    cls = ["btn", "small"] ++ cls
    ~s[<a class="#{Enum.join(cls, " ")}" id="#{params[:id]}" href="#{params[:href]}">#{params[:title]}</a>]
  end

end