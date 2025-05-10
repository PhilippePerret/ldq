defmodule Feature.BookTestMeths do
  @moduledoc """
  Module pour checker les livres

  """
  use LdQWeb.FeatureCase, async: false

  alias LdQ.Repo
  import Ecto.Query

  alias LdQ.Library, as: Lib
  alias LdQ.Library.Book
  alias LdQ.Library.Author

  @doc """

  @return Le livre trouvé (if any) ou les livres (Liste)
  """
  def assert_book_exists(params) do
    query = from(b in Book.MiniCard, join: w in Author, on: [id: b.author_id])
    query = 
      if params[:after] do
        where(query, [b], b.inserted_at > ^params[:after])
      else query end
    query = 
      if params[:author_email] do
        where(query, [b, w], w.email == ^params[:author_email])
      else query end
    
    # On soumet la requête
    books = Repo.all(query)

    actual_nb = Enum.count(books)
    expect_nb = params[:count] || 1

    # --- Vérification ---
    assert(actual_nb == expect_nb, "On aurait dû trouver #{expect_nb} livre(s) avec les paramètres #{inspect params}, on en a trouvé #{actual_nb}.")

    if expect_nb == 1 do
      Enum.at(books, 0)
    else
      books
    end
  end

end