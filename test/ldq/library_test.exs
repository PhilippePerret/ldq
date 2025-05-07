defmodule LdQ.LibraryTest do
  use LdQ.DataCase

  alias LdQ.Library

  describe "authors" do
    alias LdQ.Library.Author

    import LdQ.LibraryFixtures

    @invalid_attrs %{}

    test "list_authors/0 returns all authors" do
      author = author_fixture()
      assert Library.list_authors() == [author]
    end

    test "get_author!/1 returns the author with given id" do
      author = author_fixture()
      assert Library.get_author!(author.id) == author
    end

    test "create_author/1 with valid data creates a author" do
      valid_attrs = %{}

      assert {:ok, %Author{} = author} = Library.create_author(valid_attrs)
    end

    test "create_author/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_author(@invalid_attrs)
    end

    test "update_author/2 with valid data updates the author" do
      author = author_fixture()
      update_attrs = %{}

      assert {:ok, %Author{} = author} = Library.update_author(author, update_attrs)
    end

    test "update_author/2 with invalid data returns error changeset" do
      author = author_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_author(author, @invalid_attrs)
      assert author == Library.get_author!(author.id)
    end

    test "delete_author/1 deletes the author" do
      author = author_fixture()
      assert {:ok, %Author{}} = Library.delete_author(author)
      assert_raise Ecto.NoResultsError, fn -> Library.get_author!(author.id) end
    end

    test "change_author/1 returns a author changeset" do
      author = author_fixture()
      assert %Ecto.Changeset{} = Library.change_author(author)
    end
  end

  describe "book_minicards" do
    alias LdQ.Library.Book.MiniCard

    import LdQ.LibraryFixtures

    @invalid_attrs %{title: nil, pitch: nil}

    test "list_book_minicards/0 returns all book_minicards" do
      mini_card = mini_card_fixture()
      assert Library.list_book_minicards() == [mini_card]
    end

    test "get_mini_card!/1 returns the mini_card with given id" do
      mini_card = mini_card_fixture()
      assert Library.get_mini_card!(mini_card.id) == mini_card
    end

    test "create_mini_card/1 with valid data creates a mini_card" do
      valid_attrs = %{title: "some title", pitch: "some pitch"}

      assert {:ok, %MiniCard{} = mini_card} = Library.create_mini_card(valid_attrs)
      assert mini_card.title == "some title"
      assert mini_card.pitch == "some pitch"
    end

    test "create_mini_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_mini_card(@invalid_attrs)
    end

    test "update_mini_card/2 with valid data updates the mini_card" do
      mini_card = mini_card_fixture()
      update_attrs = %{title: "some updated title", pitch: "some updated pitch"}

      assert {:ok, %MiniCard{} = mini_card} = Library.update_mini_card(mini_card, update_attrs)
      assert mini_card.title == "some updated title"
      assert mini_card.pitch == "some updated pitch"
    end

    test "update_mini_card/2 with invalid data returns error changeset" do
      mini_card = mini_card_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_mini_card(mini_card, @invalid_attrs)
      assert mini_card == Library.get_mini_card!(mini_card.id)
    end

    test "delete_mini_card/1 deletes the mini_card" do
      mini_card = mini_card_fixture()
      assert {:ok, %MiniCard{}} = Library.delete_mini_card(mini_card)
      assert_raise Ecto.NoResultsError, fn -> Library.get_mini_card!(mini_card.id) end
    end

    test "change_mini_card/1 returns a mini_card changeset" do
      mini_card = mini_card_fixture()
      assert %Ecto.Changeset{} = Library.change_mini_card(mini_card)
    end
  end

  describe "book_specs" do
    alias LdQ.Library.Book.Specs

    import LdQ.LibraryFixtures

    @invalid_attrs %{label: nil, isbn: nil, published_at: nil, subtitle: nil, label_year: nil, url_command: nil}

    test "list_book_specs/0 returns all book_specs" do
      specs = specs_fixture()
      assert Library.list_book_specs() == [specs]
    end

    test "get_specs!/1 returns the specs with given id" do
      specs = specs_fixture()
      assert Library.get_specs!(specs.id) == specs
    end

    test "create_specs/1 with valid data creates a specs" do
      valid_attrs = %{label: true, isbn: "some isbn", published_at: ~N[2025-05-06 04:05:00], subtitle: "some subtitle", label_year: 42, url_command: "some url_command"}

      assert {:ok, %Specs{} = specs} = Library.create_specs(valid_attrs)
      assert specs.label == true
      assert specs.isbn == "some isbn"
      assert specs.published_at == ~N[2025-05-06 04:05:00]
      assert specs.subtitle == "some subtitle"
      assert specs.label_year == 42
      assert specs.url_command == "some url_command"
    end

    test "create_specs/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_specs(@invalid_attrs)
    end

    test "update_specs/2 with valid data updates the specs" do
      specs = specs_fixture()
      update_attrs = %{label: false, isbn: "some updated isbn", published_at: ~N[2025-05-07 04:05:00], subtitle: "some updated subtitle", label_year: 43, url_command: "some updated url_command"}

      assert {:ok, %Specs{} = specs} = Library.update_specs(specs, update_attrs)
      assert specs.label == false
      assert specs.isbn == "some updated isbn"
      assert specs.published_at == ~N[2025-05-07 04:05:00]
      assert specs.subtitle == "some updated subtitle"
      assert specs.label_year == 43
      assert specs.url_command == "some updated url_command"
    end

    test "update_specs/2 with invalid data returns error changeset" do
      specs = specs_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_specs(specs, @invalid_attrs)
      assert specs == Library.get_specs!(specs.id)
    end

    test "delete_specs/1 deletes the specs" do
      specs = specs_fixture()
      assert {:ok, %Specs{}} = Library.delete_specs(specs)
      assert_raise Ecto.NoResultsError, fn -> Library.get_specs!(specs.id) end
    end

    test "change_specs/1 returns a specs changeset" do
      specs = specs_fixture()
      assert %Ecto.Changeset{} = Library.change_specs(specs)
    end
  end

  describe "book_evaluations" do
    alias LdQ.Library.Book.Evaluation

    import LdQ.LibraryFixtures

    @invalid_attrs %{transmitted: nil, current_phase: nil, submitted_at: nil, evaluated_at: nil, label_grade: nil, rating: nil, readers_rating: nil}

    test "list_book_evaluations/0 returns all book_evaluations" do
      evaluation = evaluation_fixture()
      assert Library.list_book_evaluations() == [evaluation]
    end

    test "get_evaluation!/1 returns the evaluation with given id" do
      evaluation = evaluation_fixture()
      assert Library.get_evaluation!(evaluation.id) == evaluation
    end

    test "create_evaluation/1 with valid data creates a evaluation" do
      valid_attrs = %{transmitted: true, current_phase: 42, submitted_at: ~N[2025-05-06 04:07:00], evaluated_at: ~N[2025-05-06 04:07:00], label_grade: 42, rating: 42, readers_rating: 42}

      assert {:ok, %Evaluation{} = evaluation} = Library.create_evaluation(valid_attrs)
      assert evaluation.transmitted == true
      assert evaluation.current_phase == 42
      assert evaluation.submitted_at == ~N[2025-05-06 04:07:00]
      assert evaluation.evaluated_at == ~N[2025-05-06 04:07:00]
      assert evaluation.label_grade == 42
      assert evaluation.rating == 42
      assert evaluation.readers_rating == 42
    end

    test "create_evaluation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Library.create_evaluation(@invalid_attrs)
    end

    test "update_evaluation/2 with valid data updates the evaluation" do
      evaluation = evaluation_fixture()
      update_attrs = %{transmitted: false, current_phase: 43, submitted_at: ~N[2025-05-07 04:07:00], evaluated_at: ~N[2025-05-07 04:07:00], label_grade: 43, rating: 43, readers_rating: 43}

      assert {:ok, %Evaluation{} = evaluation} = Library.update_evaluation(evaluation, update_attrs)
      assert evaluation.transmitted == false
      assert evaluation.current_phase == 43
      assert evaluation.submitted_at == ~N[2025-05-07 04:07:00]
      assert evaluation.evaluated_at == ~N[2025-05-07 04:07:00]
      assert evaluation.label_grade == 43
      assert evaluation.rating == 43
      assert evaluation.readers_rating == 43
    end

    test "update_evaluation/2 with invalid data returns error changeset" do
      evaluation = evaluation_fixture()
      assert {:error, %Ecto.Changeset{}} = Library.update_evaluation(evaluation, @invalid_attrs)
      assert evaluation == Library.get_evaluation!(evaluation.id)
    end

    test "delete_evaluation/1 deletes the evaluation" do
      evaluation = evaluation_fixture()
      assert {:ok, %Evaluation{}} = Library.delete_evaluation(evaluation)
      assert_raise Ecto.NoResultsError, fn -> Library.get_evaluation!(evaluation.id) end
    end

    test "change_evaluation/1 returns a evaluation changeset" do
      evaluation = evaluation_fixture()
      assert %Ecto.Changeset{} = Library.change_evaluation(evaluation)
    end
  end
end
