defmodule LdQ.BookTests do
  use LdQ.DataCase

  import FeaturePublicMethods
  alias Random.Methods, as: Rand

  alias LdQ.Library.Book

  test "On peut créer un livre à partir de données minimales" do

    # --- Vérification préliminaire ---
    assert Enum.empty?(Book.get_all())

    # --- test ---
    Book.save(%{"title" => {nil, "Le nouveau titre"}})

    # --- Vérification ---
    assert Book.get_all() |> Enum.count == 1

  end


  test "On ne peut pas créer deux livres avec le même titre" do
    # --- Vérification préliminaire ---
    assert Enum.empty?(Book.get_all())
    # --- Préparation ---
    Book.save(%{"title" => {nil, "Le nouveau titre"}})
    assert Book.get_all() |> Enum.count == 1
    # --- Test ---
    Book.save(%{"title" => {nil, "Le nouveau titre"}, "pitch" => {nil, "Le pitch de l'autre book, qui doit être conservé."}})
    # --- Vérification post-test ---
    assert( Book.get_all() |> Enum.count == 1, "On devrait toujours n'avoir qu'un seul livre.")
  end


  test "On peut actualiser les données d'un livre" do
    # --- Vérification préliminaire ---
    assert Enum.empty?(Book.get_all())
    # --- Préparation ---
    book = Book.save(%{"title" => {nil, "Le titre du nouveau"}})
    book_id = book.id
    # --- Vérification préparation ---
    assert Book.get_all() |> Enum.count == 1
    assert(Book.get(book_id, [:title]).title == "Le titre du nouveau")
    # --- Test ---
    Book.save(%{"id" => {book_id, nil}, "title" => {"Le titre du nouveau", "Un nouveau titre pour le titre du nouveau"}})
    # --- Vérification post-test ---
    assert Book.get_all() |> Enum.count == 1
    assert(Book.get(book_id, [:title]).title == "Un nouveau titre pour le titre du nouveau")
  end

  test "Un livre peut retourner son auteur s'il existe" do
    # --- Préparation ---
    author = make_author(%{firstname: "Tanguy", lastname: "EtLaverdure"})
    book = Book.save(%{"author_id" => {nil, author.id}, "title" => "Le livre avec auteur"})
    # --- Test ---
    booked = Book.get(book.id, [:title, :author])
    # --- Vérification post-test ---
    assert booked.id == book.id
    assert booked.author.id == author.id
    assert booked.author.name == "Tanguy EtLaverdure"
  end

  test "Un livre peut retrouver son éditeur s'il existe" do
    # --- Préparation ---
    publisher = make_publisher()
    book = Book.save(%{"publisher_id" => publisher.id, "title" => "Le livre avec un éditeur au bout"})
    # --- Test ---
    booked = Book.get(book.id, [:title, :publisher])
    # IO.inspect(booked, label: "BOOKED")
    # --- Vérification post-test ---
    assert booked.id == book.id
    assert booked.publisher.id == publisher.id
    assert booked.publisher.name == publisher.name
  end

  test "get(id, :all) permet de relever toutes les propriétés du livre" do
    # --- Préparation ---
    publisher = make_publisher()
    parrain   = make_member()
    author    = make_author()
    book = Book.save(%{
      "author_id"       => author.id,
      "current_phase"   => "12",
      "isbn"            => Rand.random_isbn(),
      "publisher_id"    => publisher.id,
      "parrain_id"      => parrain.id,
      "label"           => "true",
      "label_year"      => "2025",
      "pitch"           => "C'est le résumé très court du livre",
      "published_at"    => "2025-05-18",
      "rating"          => "123",
      "title"           => "Le titre du livre avec toutes les propriétés"
      })
    # |> IO.inspect(label: "\nBOOK")
    # --- Test ---
    booked = Book.get(book.id, :all)
    # IO.inspect(booked, label: "BOOKED")
    # --- Vérification post-test ---
    Map.keys(Book.fields_data)
    |> Enum.each(fn field_str ->
      field_key = String.to_atom(field_str)
      value = Map.get(booked, field_key)
      refute( is_nil(value), "Le champ #{inspect field_key} ne devrait pas être nil…")
      assert(value == Map.get(book, field_key), "Le champ #{inspect field_key} n'a pas la bonne valeur…\nAttendue: #{inspect value}\nObtenue:  #{inspect Map.get(book, field_key)}")
    end)
  end


  test "On ne peut pas passer à une phase inférieure" do
    # --- Préparation ---
    book = Book.save(%{"current_phase" => {"10", "11"}})
    assert(is_struct(book, Book))
    # --- Test ---
    bad_book = Book.save(%{"current_phase" => {"11", "10"}})
    # IO.inspect(bad_book, label: "\nBAD BOOK")
    # --- Vérification ---
    refute(is_struct(bad_book, Book))
    assert(Enum.at(bad_book.invalid, 0) == {"current_phase", "La nouvelle phase courante (10) devrait être supérieure à la phase précédente (11)"})
  end

  test "On ne peut pas définir l'année de labélisation à un livre non labélisé" do
    # --- Préparation ---
    book_non_labeled = Book.save(%{"title" => "Mon livre non labélisé"})
    # --- Test 1 (définition de l'année à livre non labélisé) ---
    res = Book.save(%{"id" => book_non_labeled.id, "label_year" => "2025"})
    refute(is_struct(res, Book))
    assert(Enum.at(res.invalid, 0) |> Tuple.to_list() |> Enum.at(0) == "label_year")
    # --- Test 2 (création d'un livre non labélisé) ---
    book = Book.save(%{"label_year" => "2025"})
    refute(is_struct(book, Book))
    assert(Enum.at(book.invalid, 0) |> Tuple.to_list() |> Enum.at(0) == "label_year")
  end

  test "L'année de labélisation d'un livre dont on retire le label doit être mise à nul" do
    # --- Préparation ---
    book = Book.save(%{"label" => "true", "label_year" => "2000"})
    # --- Pré-vérification ---
    assert(is_struct(book, Book), "Le résultat devrait être un livre. C'est : #{inspect book}")
    book = Book.get(book.id, [:label, :label_year])
    assert(book.label === true)
    assert(book.label_year == 2000)
    # --- Test ---
    res = Book.save(book, %{"label" => "false"})
    IO.inspect(res, label: "\nRES d'UPDATE")
    # --- Vérification ---
    book = Book.get(book.id, [:label, :label_year])
    assert(book.label === false)
    assert(is_nil(book.label_year), "L'année du label aurait avoir dû être mise à false.")
  end

end