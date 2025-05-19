defmodule LdQ.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LdQ.Library` context.
  """

  import Random.Methods


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

end
