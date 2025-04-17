defmodule LdQ.Site do
  @moduledoc """
  The Site context.
  """

  import Ecto.Query, warn: false
  alias LdQ.Repo

  alias LdQ.Site.{Page, PageLocale}

  @doc """
  Pour vérifier qu'une page locale n'existe pas déjà

  @return {:yes, <page locale>} en cas de succès et :no en cas d'échec
  """
  def has_locale_page?(params) do
    pageid = params["page_id"]
    locale = params["locale"]
    
    res =
    from(pl in PageLocale, where: pl.page_id == ^pageid and pl.locale == ^locale, select: pl.id)
    |> Repo.one()
    case res do
      nil -> :no
      _ -> {:yes, res}
    end
  end

  @doc """
  Returns the list of pages.

  ## Examples

      iex> list_pages()
      [%Page{}, ...]

  """
  def list_pages do
    Repo.all(Page)
  end

  @doc """
  Gets a single page.

  Raises `Ecto.NoResultsError` if the Page does not exist.

  ## Examples

      iex> get_page!(123)
      %Page{}

      iex> get_page!(456)
      ** (Ecto.NoResultsError)

  """
  def get_page!(id), do: Repo.get!(Page, id)

  @doc """
  Creates a page.

  ## Examples

      iex> create_page(%{field: value})
      {:ok, %Page{}}

      iex> create_page(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_page(attrs \\ %{}) do
    %Page{}
    |> Page.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a page.

  ## Examples

      iex> update_page(page, %{field: new_value})
      {:ok, %Page{}}

      iex> update_page(page, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_page(%Page{} = page, attrs) do
    page
    |> Page.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a page.

  ## Examples

      iex> delete_page(page)
      {:ok, %Page{}}

      iex> delete_page(page)
      {:error, %Ecto.Changeset{}}

  """
  def delete_page(%Page{} = page) do
    Repo.delete(page)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking page changes.

  ## Examples

      iex> change_page(page)
      %Ecto.Changeset{data: %Page{}}

  """
  def change_page(%Page{} = page, attrs \\ %{}) do
    Page.changeset(page, attrs)
  end

  @doc """
  Returns the list of page_locales.

  ## Examples

      iex> list_page_locales()
      [%PageLocale{}, ...]

  """
  def list_page_locales do
    # Repo.all(PageLocale)
    from( pl in PageLocale, preload: [:page])
    |> Repo.all()
  end

  @doc """
  Gets a single page_locale.

  Raises `Ecto.NoResultsError` if the Page locale does not exist.

  ## Examples

      iex> get_page_locale!(123)
      %PageLocale{}

      iex> get_page_locale!(456)
      ** (Ecto.NoResultsError)

  """
  def get_page_locale!(id) do
    Repo.get!(PageLocale, id)
    |> Repo.preload(:page)
  end

  @doc """
  Creates a page_locale.

  ## Examples

      iex> create_page_locale(%{field: value})
      {:ok, %PageLocale{}}

      iex> create_page_locale(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_page_locale(attrs \\ %{}) do
    %PageLocale{}
    |> PageLocale.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a page_locale.

  ## Examples

      iex> update_page_locale(page_locale, %{field: new_value})
      {:ok, %PageLocale{}}

      iex> update_page_locale(page_locale, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_page_locale(%PageLocale{} = page_locale, attrs) do
    page_locale
    |> PageLocale.changeset(attrs)
    |> IO.inspect(label: "\nCHANGESET")
    |> Repo.update()
  end

  @doc """
  Deletes a page_locale.

  ## Examples

      iex> delete_page_locale(page_locale)
      {:ok, %PageLocale{}}

      iex> delete_page_locale(page_locale)
      {:error, %Ecto.Changeset{}}

  """
  def delete_page_locale(%PageLocale{} = page_locale) do
    Repo.delete(page_locale)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking page_locale changes.

  ## Examples

      iex> change_page_locale(page_locale)
      %Ecto.Changeset{data: %PageLocale{}}

  """
  def change_page_locale(%PageLocale{} = page_locale, attrs \\ %{}) do
    PageLocale.changeset(page_locale, attrs)
  end
end
