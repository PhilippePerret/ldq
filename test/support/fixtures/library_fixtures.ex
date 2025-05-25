defmodule LdQ.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LdQ.Library` context.
  """

  alias LdQ.Repo

  import Ecto.Query

  import Random.Methods

  alias LdQ.Library.{Book, UserBook}


  @doc """
  Generate a author.
  """
  def author_fixture(attrs \\ %{}) do
    sexe = random_sexe()
    {:ok, author} =
      Map.merge(%{
        firstname:  random_firstname(sexe),
        lastname:   random_lastname(),
        sexe:       sexe,
        email:      "author#{uniq_int()}@example.com",
        birthyear:  Enum.random((1960..2010))
      }, attrs)
      |> LdQ.Library.create_author()

    author
  end
  def make_author(attrs \\ %{}), do: author_fixture(attrs)

  def book_fixture(attrs \\ %{}) do
    author = make_author()
    publisher = 
      if Enum.random((1..40)) > 20 do
        make_publisher()
      else
        random_publisher()
      end
    attrs = Map.merge(%{
      title: random_title(),
      isbn: random_isbn(),
      author_id: author.id, 
      publisher_id: publisher.id,
      transmitted: true, 
      submitted_at: random_time(:before, Enum.random(1000..100000))
    }, attrs)
    LdQ.Library.Book.save(attrs)
  end
  def make_book(attrs \\ %{}), do: book_fixture(attrs)


  def make_publisher(attrs \\ %{}) do
    {:ok, publisher} =
      Map.merge(%{
        name:     random_publisher_name(),
        addess:   random_address(),
        email:    random_email(),
        pays:     random_pays(:dim)
      }, attrs)
      |> LdQ.Library.create_publisher()
    
    publisher
  end

  @publisher_names ~w(Gallimard Flamarion Albin Michel Icare Éditions Marvel Seuil Acte Sud Pol PUF Fayard Larousse Belin Oxford Editions)
  defp random_publisher_name do
    Enum.random(@publisher_names)
  end

  @doc """
  Retourne un éditeur au hasard
  """
  def random_publisher do
    publisher_ids =
      from(p in LdQ.Library.Publisher, select: p.id)
      |> Repo.all()

    if Enum.empty?(publisher_ids) do
      # Si aucun éditeur n'a été trouvé, on en crée un
      make_publisher()
    else
      publisher_id = 
        publisher_ids
        |> Enum.random()
      Repo.get!(LdQ.Library.Publisher, publisher_id)
    end
  end

  def random_book_or_create(options \\ []) do
    query = from(b in Book, select: b.id)

    query =
      if options[:not_read_by] do
        user = options[:not_read_by]
        join(query, :inner, [b], ub in UserBook, on: ub.book_id == b.id)
        |> where([b, ub], ub.user_id != ^user.id)
      else 
        query 
      end

    all_book_ids = Repo.all(query)

    if Enum.empty?(all_book_ids) do
      # Aucun livre trouvé, on en fait un nouveau
      make_book()
    else
      # On a trouvé un livre non lu par l'user
      all_book_ids
      |> Enum.random()
      |> Book.get()
    end
  end

end
