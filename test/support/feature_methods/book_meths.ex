defmodule Feature.BookTestMeths do
  @moduledoc """
  Module pour checker les livres

  """
  use LdQWeb.FeatureCase, async: false

  alias LdQ.Repo
  import Ecto.Query

  # alias LdQ.Library, as: Lib
  alias LdQ.Library.Book
  alias LdQ.Library.Author

  @doc """
  Fonction qui s'assure qu'un livre existe bien avec les propriétés
  +params+

  @param {Map} params Les paramètres de recherche
    En plus des propriétés du livre, +params+ peut définir :count qui précise
    le nombre de livres attendus. Si :count vaut 1, seul ce livre sera 
    renvoyé, sinon c'est une liste de {Book}.
    
  @return Le livre trouvé (if any) ou les livres (Liste)
  """
  def assert_book_exists(params) do
    query = from(b in Book)
    query = join(query, :inner, [b], w in Author, on: [id: b.author_id])

    query = 
      if params[:after] do
        where(query, [b], b.inserted_at > ^params[:after])
      else query end
    query = 
      [:id, :email, :firstname, :lastname]
      |> Enum.reduce(query, fn prop, query ->
        db_prop = prop
        pm_prop = String.to_atom("author_#{prop}")
        valeur = params[pm_prop]
        if is_nil(valeur) do 
          query
        else
          where(query, [b, w], field(w, ^db_prop) == ^valeur)
        end
      end)
    
    # On soumet la requête
    books = Repo.all(query) |> Repo.preload(:author)

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

  @doc """
  Fixture des livres avec les paramètres +params+
  """
  def make_books(params \\ []), do: LdQ.LibraryFixtures.make_books(params)

end