defmodule LdQ.BookTests do
  use LdQ.DataCase

  import FeaturePublicMethods

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
    IO.inspect(book, label: "BOOK")
    # --- Test ---
    booked = Book.get(book.id, [:title, :author])
    # --- Vérification post-test ---
    assert booked.id == book.id
    assert booked.author_id == author.id
    assert booked.author_name == "Tanguy EtLaverdure"
    assert booked.author.name == "Tanguy EtLaverdure"
  end

end