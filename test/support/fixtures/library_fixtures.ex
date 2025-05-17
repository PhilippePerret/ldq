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

  @doc """
  Generate a mini_card.
  """
  def mini_card_fixture(attrs \\ %{}) do
    {:ok, mini_card} =
      attrs
      |> Enum.into(%{
        pitch: "some pitch",
        title: "some title"
      })
      |> LdQ.Library.create_mini_card()

    mini_card
  end

  @doc """
  Generate a specs.
  """
  def specs_fixture(attrs \\ %{}) do
    {:ok, specs} =
      attrs
      |> Enum.into(%{
        isbn: "some isbn",
        label: true,
        label_year: 42,
        published_at: ~N[2025-05-06 04:05:00],
        subtitle: "some subtitle",
        url_command: "some url_command"
      })
      |> LdQ.Library.create_specs()

    specs
  end

  @doc """
  Generate a evaluation.
  """
  def evaluation_fixture(attrs \\ %{}) do
    {:ok, evaluation} =
      attrs
      |> Enum.into(%{
        current_phase: 42,
        evaluated_at: ~N[2025-05-06 04:07:00],
        label_grade: 42,
        rating: 42,
        readers_rating: 42,
        submitted_at: ~N[2025-05-06 04:07:00],
        transmitted: true
      })
      |> LdQ.Library.create_evaluation()

    evaluation
  end
end
