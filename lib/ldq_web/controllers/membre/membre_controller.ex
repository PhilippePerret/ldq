defmodule LdQWeb.MembreController do
  use LdQWeb, :controller

  alias LdQ.Comptes
  alias LdQ.Comptes.User
  alias LdQ.Evaluation.UserBook
  alias LdQ.Library.Book

  @doc """
  Tableau de bord du membre du comité de lecture.
  """
  # Quand on arrive dans le tableau de bord avec une opération
  def dashboard(conn, %{"membre_id" => _membre_id, "op" => op} = params) do
    conn = conn |> put_flash(:info, "Opération choisie : #{inspect op}")
    membre = get_membre_from(params)
    res = exec_op(op, membre, params)
    conn = if res[:msg] do
      conn |> put_flash(:info, res[:msg])
    else conn end
    common_render(conn, membre)
  end
  # Quand on arrive sur le tableau de bord sans rien
  def dashboard(conn, %{"membre_id" => _membre_id } = params) do
    common_render(conn, get_membre_from(params))
  end

  # === Méthode générale qui rend le bureau du membre ===
  defp common_render(conn, membre) do
    render(conn, :home, membre: membre)
  end

  defp get_membre_from(%{"membre_id" => membre_id} = _params) do
    Comptes.get_user_as_membre!(membre_id) || raise("Intrusion inopinée.")
  end

  # === Toutes les méthodes d'opération ===

  # Choix d'un livre à évaluer
  # À quoi correspond le fait d'évaluer un livre ? C'est en fait la
  # création d'une fiche d'évaluation association le membre au livre
  defp exec_op("choose-for-eval", membre, %{"id" => book_id, "type" => type} = _params) do
    type == "book" || raise(@errors[:book_required])
    book = Book.get(book_id) || raise(eval_error(:unknown_book, [book_id: book_id]))
    UserBook.assoc_user_and_book(membre, book)
    [msg: "#{membre.name}, vous pouvez à présent évaluer le livre #{book.title}"]
  end


  # Refus d'un parrainage par le membre courant
  defp exec_op("refus-parrainage", membre, %{"id" => book_id, "type" => type} = _params) do
    type == "book" || raise(@errors[:book_required])
    book = Book.get(book_id, [:parrain, :id, :title, :author]) || raise(eval_error(:unknown_book, [book_id: book_id]))
    parrain = book.parrain
    # Retirer le parrain au livre
    newbook = Book.save(book, %{parrain_id: {book.parrain.id, nil}})
    cond do
    is_binary(newbook) -> 
      [msg: "#{membre.name}, je n'ai pas réussi à vous “déparrainer”. Merci d'en informer l'administrateur."]
    true ->
      # Retirer les points au parrain
      points_parrain =  LdQ.Evaluation.CreditCalculator.points_for(:parrainage)
      User.update_credit(membre, membre.credit - points_parrain)
      # Prévenir l'administration
      LdQ.Mailer.send_phil_mail(to: :admin, from: parrain.email, with: %{
        mail_id:    "refus-parrainage",
        variables:  [book_url: ~s(<a href="/livre/#{book_id}">Fiche du livre</a>)]
      })
      [msg: "#{membre.name}, vous ne parrainez plus le livre #{book.title}."]
    end
  end


  @errors %{
    book_required: "Il devrait être question d'un livre",
    unknown_book:  "Le livre d'identifiant \#{book_id} est inconnu…"
  }

  defp eval_error(err_id, data) do
    err_msg = @errors[err_id]
    {erreur, _binding} = Code.eval_string(~s("#{err_msg}"), data)
    erreur
  end

end