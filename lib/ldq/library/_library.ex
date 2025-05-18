defmodule LdQ.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false
  alias LdQ.Repo

  alias LdQ.Library.Author
  alias LdQ.Library.Publisher

  alias LdQ.Library.Book

  @doc """
  Returns the list of authors.

  ## Examples

      iex> list_authors()
      [%Author{}, ...]

  """
  def list_authors do
    Repo.all(Author)
  end

  @doc """
  Gets a single author.

  Raises if the Author does not exist.

  ## Examples

      iex> get_author!(123)
      %Author{}

  """
  def get_author!(id) do
    Repo.get!(Author, id)
  end

  @doc """
  Creates a author.

  ## Examples

      iex> create_author(%{field: value})
      {:ok, %Author{}}

      iex> create_author(%{field: bad_value})
      {:error, ...}

  """
  def create_author(attrs \\ %{}) do
    %Author{}
    |> Author.changeset(attrs)
    |> Repo.insert()
  end
  def create_author!(attrs \\ %{}) do
    case create_author(attrs) do
    {:ok, author} -> author
    {:error, changeset} ->
      raise(inspect changeset)
      nil
    end
  end

  @doc """
  Updates a author.

  ## Examples

      iex> update_author(author, %{field: new_value})
      {:ok, %Author{}}

      iex> update_author(author, %{field: bad_value})
      {:error, ...}

  """
  def update_author(%Author{} = author, attrs) do
    author
    |> Author.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Author.

  ## Examples

      iex> delete_author(author)
      {:ok, %Author{}}

      iex> delete_author(author)
      {:error, ...}

  """
  def delete_author(%Author{} = author) do
    Repo.delete(author)
  end

  @doc """
  Returns a data structure for tracking author changes.

  ## Examples

      iex> change_author(author)
      %Todo{...}

  """
  def change_author(%Author{} = author, _attrs \\ %{}) do
    raise "TODO"
  end

  @doc """
  Créer un nouveau publisher (éditeur)

  @return {:ok, publisher} en cas de succès ou {:error, changeset} en
  cas d'erreur
  """
  def create_publisher(attrs) do
    %Publisher{}
    |> Publisher.changeset(attrs)
    |> Repo.insert()
  end

  def create_publisher!(attrs) do
    case create_publisher(attrs) do
      {:ok, publisher} -> publisher
      {:error, changeset} -> nil
    end
  end

  @doc """
  Retourne tous les éditeurs

  """
  def get_publishers do
    Repo.all(Publisher)
  end

  @doc """
  Retourne l'éditeur d'identifiant +id+
  """
  def get_publisher!(id) do
    Repo.get!(Publisher, id)
  end

  @doc """
  Retourne un éditeur par son nom (s'il existe) ou nil s'il n'existe
  pas.

  @return {Publisher|Nil}
  """
  def get_publisher_by_name(name) do
    from(p in Publisher, where: p.name == ^name)
    |> Repo.one()
  end

  @doc """
  Retourne les valeurs pour choisir un éditeur dans la liste exis-
  tante
  """
  def publishers_for_select do
    get_publishers()
    |> Enum.sort_by(&(&1.name))
    |> Enum.map(fn pub ->
      [pub.name, pub.id]
    end)
    |> List.insert_at(0, ["Choisir…", ""])
  end

  def delete_publisher(%Publisher{} = publisher) do
    Repo.delete(publisher)
  end

end #/ Library
