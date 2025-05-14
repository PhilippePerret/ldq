defmodule LdQ.Library do
  @moduledoc """
  The Library context.
  """

  import Ecto.Query, warn: false
  alias LdQ.Repo

  alias LdQ.Library.Author
  alias LdQ.Library.Publisher

  alias LdQ.Library.Book.MiniCard
  alias LdQ.Library.Book.Specs
  alias LdQ.Library.Book.Evaluation

  @doc """
  Returns the list of book_minicards.

  ## Examples

      iex> list_book_minicards()
      [%MiniCard{}, ...]

  """
  def list_book_minicards do
    Repo.all(MiniCard)
  end

  @doc """
  Gets a single mini_card.

  Raises `Ecto.NoResultsError` if the Mini card does not exist.

  ## Examples

      iex> get_mini_card!(123)
      %MiniCard{}

      iex> get_mini_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_mini_card!(id), do: Repo.get!(MiniCard, id)

  def get_book(id) do
    Repo.get!(MiniCard, id)
    |> Repo.preload(:book_specs)
    |> Repo.preload(:book_evaluation)
    |> Repo.preload(:author)
  end

  @doc """
  Creates a mini_card.

  ## Examples

      iex> create_mini_card(%{field: value})
      {:ok, %MiniCard{}}

      iex> create_mini_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_book_mini_card(attrs \\ %{}) do
    %MiniCard{}
    |> MiniCard.changeset(attrs)
    |> Repo.insert()
  end
  def create_book_mini_card!(attrs \\ %{}) do
    case create_book_mini_card(attrs) do
    {:ok, mini_card} -> mini_card
    {:error, changeset} ->
      raise(inspect changeset)
      nil
    end
  end

  @doc """
  Updates a mini_card.

  ## Examples

      iex> update_mini_card(mini_card, %{field: new_value})
      {:ok, %MiniCard{}}

      iex> update_mini_card(mini_card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mini_card(%MiniCard{} = mini_card, attrs) do
    mini_card
    |> MiniCard.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a mini_card.

  ## Examples

      iex> delete_mini_card(mini_card)
      {:ok, %MiniCard{}}

      iex> delete_mini_card(mini_card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_mini_card(%MiniCard{} = mini_card) do
    Repo.delete(mini_card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mini_card changes.

  ## Examples

      iex> change_mini_card(mini_card)
      %Ecto.Changeset{data: %MiniCard{}}

  """
  def change_mini_card(%MiniCard{} = mini_card, attrs \\ %{}) do
    MiniCard.changeset(mini_card, attrs)
  end


  @doc """
  Returns the list of book_specs.

  ## Examples

      iex> list_book_specs()
      [%Specs{}, ...]

  """
  def list_book_specs do
    Repo.all(Specs)
  end

  @doc """
  Gets a single specs.

  Raises `Ecto.NoResultsError` if the Specs does not exist.

  ## Examples

      iex> get_specs!(123)
      %Specs{}

      iex> get_specs!(456)
      ** (Ecto.NoResultsError)

  """
  def get_specs!(id), do: Repo.get!(Specs, id)

  @doc """
  Creates a specs.

  ## Examples

      iex> create_specs(%{field: value})
      {:ok, %Specs{}}

      iex> create_specs(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_book_specs(attrs \\ %{}) do
    %Specs{}
    |> Specs.changeset(attrs)
    |> Repo.insert()
  end
  def create_book_specs!(attrs \\ %{}) do
    case create_book_specs(attrs) do
    {:ok, book_specs} -> book_specs
    {:error, changeset} -> 
      raise(inspect changeset)
      nil
    end
  end

  @doc """
  Updates a specs.

  ## Examples

      iex> update_specs(specs, %{field: new_value})
      {:ok, %Specs{}}

      iex> update_specs(specs, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_specs(%Specs{} = specs, attrs) do
    specs
    |> Specs.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a specs.

  ## Examples

      iex> delete_specs(specs)
      {:ok, %Specs{}}

      iex> delete_specs(specs)
      {:error, %Ecto.Changeset{}}

  """
  def delete_specs(%Specs{} = specs) do
    Repo.delete(specs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking specs changes.

  ## Examples

      iex> change_specs(specs)
      %Ecto.Changeset{data: %Specs{}}

  """
  def change_specs(%Specs{} = specs, attrs \\ %{}) do
    Specs.changeset(specs, attrs)
  end

  @doc """
  Returns the list of book_evaluations.

  ## Examples

      iex> list_book_evaluations()
      [%Evaluation{}, ...]

  """
  def list_book_evaluations do
    Repo.all(Evaluation)
  end

  @doc """
  Gets a single evaluation.

  Raises `Ecto.NoResultsError` if the Evaluation does not exist.

  ## Examples

      iex> get_evaluation!(123)
      %Evaluation{}

      iex> get_evaluation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_evaluation!(id), do: Repo.get!(Evaluation, id)

  @doc """
  Creates a evaluation.

  ## Examples

      iex> create_evaluation(%{field: value})
      {:ok, %Evaluation{}}

      iex> create_evaluation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_book_evaluation(attrs \\ %{}) do
    %Evaluation{}
    |> Evaluation.changeset(attrs)
    |> Repo.insert()
  end
  def create_book_evaluation!(attrs \\ %{}) do
    case create_book_evaluation(attrs) do
      {:ok, card} -> card
      {:error, changeset} -> 
        raise(inspect changeset)
        nil
    end
  end

  @doc """
  Updates a evaluation.

  ## Examples

      iex> update_evaluation(evaluation, %{field: new_value})
      {:ok, %Evaluation{}}

      iex> update_evaluation(evaluation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_book_evaluation(%Evaluation{} = evaluation, attrs) do
    evaluation
    |> Evaluation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a evaluation.

  ## Examples

      iex> delete_evaluation(evaluation)
      {:ok, %Evaluation{}}

      iex> delete_evaluation(evaluation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_book_evaluation(%Evaluation{} = evaluation) do
    Repo.delete(evaluation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking evaluation changes.

  ## Examples

      iex> change_evaluation(evaluation)
      %Ecto.Changeset{data: %Evaluation{}}

  """
  def change_book_evaluation(%Evaluation{} = evaluation, attrs \\ %{}) do
    Evaluation.changeset(evaluation, attrs)
  end

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
  def get_author!(id), do: Repo.one!(id)

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
  def get_publisher(id) do
    Repo.one(Publisher, id)
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
