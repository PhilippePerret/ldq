defmodule LdQWeb.MembreController do
  use LdQWeb, :controller

  alias LdQ.Comptes
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
  defp exec_op("choose-for-eval", membre, %{"id" => book_id, "type" => type} = _params) do
    # Bien sûr, il doit s'agir d'un livre
    type == "book" || raise("Il devrait s'agir d'un livre !")
    # À quoi correspond le fait d'évaluer un livre ? C'est en fait la
    # création d'une fiche d'évaluation association le membre au livre
    book = Book.get(book_id) || raise("Le livre d'identifiant #{book_id} est inconnu…")
    UserBook.assoc_user_and_book(membre, book)
    [msg: "#{membre.name}, vous pouvez à présent évaluer le livre #{book.title}"]
  end

end