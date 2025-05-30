defmodule LdQ.BookTests do
  use LdQ.DataCase

  import FeaturePublicMethods
  alias Random.Methods, as: Rand

  alias LdQ.Library.Book

  @doc """
  Pour vérifier une erreur

  Rappel : lorsque Book.save rencontre une erreur, ce n'est pas une
  structure Book qui est retournée, mais le setchange de travail. Il
  contient une propriété :invalid listant les erreurs.

  Pour le moment, on suppose que c'est la première erreur qui est
  l'erreur testée. Si, plus tard, on doit en vérifier plusieurs, on
  pourra améliorer les choses
  """
  def contains_book_error(badbook, expected_key, error_seg \\ nil) do
    {key, error} = badbook.invalid |> Enum.at(0)
    assert(key == expected_key, "C'est la clé #{inspect expected_key} qu'on attendait, pas la clé #{inspect key}")
    if error_seg do
      assert( error =~ error_seg, "On aurait dû trouver #{inspect error_seg} dans le message d'erreur #{inspect error}")
    end
  end

  @tag :skip
  test "On peut créer un livre à partir de données minimales" do

    # --- Vérification préliminaire ---
    assert Enum.empty?(Book.get_all())

    # --- test ---
    book = Book.save(%{"title" => {nil, "Le nouveau titre"}})

    # --- Vérification ---
    assert(is_struct(book, Book))
    assert Book.get_all() |> Enum.count == 1

  end

  @tag :skip
  test "On peut envoyer tout un tas de données pour créer le livre" do
    thetitre = "Le titre seul au milieu de plein de données"
    data = %{
      "title" => {nil, thetitre},
      "badkey" => "Une clé tout à fait inutile",
      "badbad" => {nil, "Celle-là fait croire qu'elle est bonne"},
      "badtype" => true
    }
    book = Book.save(data)
    # --- Vérification ---
    assert(is_struct(book, Book))
    assert(is_nil(Map.get(book, :badkey)))
    refute(is_nil(Map.get(book, :title)))
    assert(book.title == thetitre)
  end


  @tag :skip
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


  @tag :skip
  test "On peut actualiser les données d'un livre (en mettant 'id' en attribut)" do
    # --- Vérification préliminaire ---
    assert Enum.empty?(Book.get_all())
    # --- Préparation ---
    book = Book.save(%{"title" => {nil, "Le titre du nouveau"}})
    book_id = book.id
    # --- Vérification préparation ---
    assert Book.get_all() |> Enum.count == 1
    assert(Book.get(book_id, [:title]).title == "Le titre du nouveau")
    # --- Test ---
    Book.save(%{"id" => {nil, book_id}, "title" => {"Le titre du nouveau", "Un nouveau titre pour le titre du nouveau"}})
    # --- Vérification post-test ---
    assert Book.get_all() |> Enum.count == 1
    assert(Book.get(book_id, [:title]).title == "Un nouveau titre pour le titre du nouveau")
  end
  
  @tag :skip
  test "On peut actualiser les données d'un livre avec Book.save/2" do
    # --- Vérification préliminaire ---
    assert Enum.empty?(Book.get_all())
    # --- Préparation ---
    book = Book.save(%{"title" => {nil, "Le titre du nouveau"}})
    book_id = book.id
    # --- Vérification préparation ---
    assert Book.get_all() |> Enum.count == 1
    assert(Book.get(book_id, [:title]).title == "Le titre du nouveau")
    # --- Test ---
    Book.save(book, %{"title" => {"Le titre du nouveau", "Un nouveau titre pour le titre du nouveau"}})
    # --- Vérification post-test ---
    assert Book.get_all() |> Enum.count == 1
    assert(Book.get(book_id, [:title]).title == "Un nouveau titre pour le titre du nouveau")
  end

  @tag :skip
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

  @tag :skip
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

  # @tag :skip
  test "get(id, :all) permet de relever toutes les propriétés du livre" do
    # --- Préparation ---
    preversion = Book.save(%{"title" => "La version précédente."})
    publisher = make_publisher()
    parrain   = make_membre()
    author    = make_author()
    book = Book.save(%{
      "author_id"       => author.id,
      "last_phase"      => "80",
      "current_phase"   => "82",
      "evaluated_at"    => "2025-08-02 10:21:23",
      "isbn"            => Rand.random_isbn(),
      "label"           => "true",
      "label_grade"     => "2",
      "label_year"      => "2025",
      "pitch"           => "C'est le résumé très court du livre",
      "parrain_id"      => parrain.id,
      "pre_version_id"  => "#{preversion.id}",
      "published_at"    => "2025-05-18",
      "publisher_id"    => publisher.id,
      "rating"          => "123",
      "readers_rating"  => "154",
      "readers_count"   => "120",
      "submitted_at"    => "2025-06-02 11:00:23",
      "subtitle"        => "Le sous-titre du livre",
      "title"           => "Le titre du livre avec toutes les propriétés",
      "transmitted"     => "true",
      "url_command"     => "https://www.amazon.fr/dp/B09521VMZQ"
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


  @tag :skip
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

  @tag :skip
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

  @tag :skip
  test "L'année de labélisation d'un livre se met automatiquement si elle n'est pas fourni" do
    # --- Préparation ---
    book = Book.save(%{"title" => "Mon livre pas encore labélisé"})
    # --- Test 1 : en actualisation ---
    book = Book.save(book, %{"label" => "true"})
    # --- Test 2 : en créant le livre ---
    book2 = Book.save(%{"title" => "Mon livre déjà labélisé", "label" => "true"})
    # --- Vérification test 1 ---
    annee_courante = now().year
    refute( is_nil(book.label_year), "L'année de labélisation aurait dû être définie")
    assert( book.label_year == annee_courante)
    # --- Vérification test 2 ---
    refute( is_nil(book2.label_year), "L'année de labélisation aurait dû être définie")
    assert( book2.label_year == annee_courante)

  end

  @tag :skip
  test "L'année de labélisation d'un livre dont on retire le label doit être mise à nul" do
    # --- Préparation ---
    book = Book.save(%{"label" => "true", "label_year" => "2000"})
    # --- Pré-vérification ---
    assert(is_struct(book, Book), "Le résultat devrait être un livre. C'est : #{inspect book}")
    book = Book.get(book.id, [:label, :label_year])
    assert(book.label === true)
    assert(book.label_year == 2000)
    # --- Test ---
    Book.save(book, %{"label" => "false"})
    # --- Vérification ---
    book = Book.get(book.id, [:label, :label_year])
    assert(book.label === false)
    assert(is_nil(book.label_year), "L'année du label aurait avoir dû être mise à false.")
  end

  @tag :skip
  test "Le sous-titre (subtitle) du livre ne peut pas être trop long" do
    # --- Préparation/test ---
    goodbook = Book.save(%{"title" => "Le titre du livre", "subtitle" => "Un sous-titre qui est largement assez court."})
    assert is_struct(goodbook, Book)
    badbook = Book.save(%{
      "title" => "Le titre du mauvais livre", 
      "subtitle" => String.duplicate("Ceci est une courte portion ", 15)
    })
    refute(is_struct(badbook, Book))
    contains_book_error(badbook, "subtitle")
  end

  @tag :skip
  test "L'URL de commande du livre doit être bien formaté et valide" do
    # Book avec une URL mal formatée
    badbook = Book.save(%{
      "title" => "Livre avec une URL qui n'en est pas une",
      "url_command" => "une/vraiment/mauvaise"
    })
    refute(is_struct(badbook, Book), "Le livre avec une URL de commande mal formatée ne devrait pas être un Book…")
    contains_book_error(badbook, "url_command", "n'est pas une URL valide")
    badbook = Book.save(%{
      "title" => "Livre avec une URL bien formatée mais inexistante",
      "url_command" => "h t t p s ://www.amazon.fr/dpdp/B09521VMZQ"
    })
    refute(is_struct(badbook, Book), "Le livre avec un URL de commande morte ne devrait pas être un Book")
    contains_book_error(badbook, "url_command", "est une URL qui ne conduit nulle part")
    # Une bonne URL existante
    goodbook = Book.save(%{
      "title" => "Livre avec une url de commande valide",
      "url_command" => "https://www.amazon.fr/dp/B09521VMZQ"
      })
    assert(is_struct(goodbook, Book))
  end

  @tag :skip
  test "S'il y a une pré-version (pre_version_id), elle doit exister" do
    # TODO
  end

  @tag :skip
  test "Si le manuscrit/epub a été transmis, il faut qu'il existe" do
    # Note : il est dans un dossier connu, avec un nom standardisé
    # TODO
  end

  @tag :skip
  test "On doit savoir quand le livre a été soumis pour évaluation" do
    # Note : c'est la date où l'administrateur valide la soumission
    # TODO
    # Il ne doit pas être défini quand l'utilisateur/auteur le soumet
    # TODO
    # Il est défini quand l'administrateur valide la soumission
    # TODO
  end

  @tag :skip
  test "La date d'évaluation est fixée quand le livre reçoit ou non le label" do
    # Un livre qui reçoit le label
    # TODO
    # Un livre qui ne reçoit pas le label
    # TODO
  end

  @tag :skip
  test "On peut définir le grade du label du livre" do
    # TODO
  end
  @tag :skip
  test "Le grade du label ne peut être défini si le livre n'a pas été évalué" do
    # TODO
  end
  @tag :skip
  test "Le grade du label ne peut être défini si le label est refusé au livre" do
    # TODO
  end
  @tag :skip
  test "Quand on retire le label à un livre, son grade de label s'annule" do
    # TODO
  end
  @tag :skip
  test "On peut définir le :rating d'un livre et l'augmenter" do
    # TODO
  end
  @tag :skip
  test "Un reader peut augmenter le rating" do
    # TODO
  end
  @tag :skip
  test "Un reader peut diminuer le rating" do
    # TODO
  end
  @tag :skip
  test "Un reader peut changer son rating (mais il a un seul rating quand même)" do
    # TODO
  end

  @tag :skip
  test "La méthode add permet d'ajouter des propriétés enregistrées" do
    # --- Préparation ---
    book_id = Book.save(%{
      "title" => "Le livre dont il faut ajouter des choses",
      "pitch" => "C'est un livre qui permet de tester l'ajout en direct de données dans la table grâce à la méthode add/2",
      "subtitle" => "C'est un sous-titre actif du livre",
      "submitted_at" => "2024-12-23 10:21:00",
      "label" => "true",
      "label_year" => "2024",
    }).id
    # --- Test ---
    book = Book.get(book_id, [:title])
    # IO.inspect(book, label: "\nBOOK")
    # --- Vérification dans le test ---
    assert is_nil(book.pitch)
    assert book.label === false
    assert is_nil(book.label_year)
    assert is_nil(book.submitted_at)
    # --- Suite test ---
    book = Book.add(book, [:label, :label_year, :pitch, :submitted_at])
    # --- Vérification post-test ---
    refute is_nil(book.pitch)
    assert book.label === true
    assert book.label_year == 2024
    assert book.submitted_at == NaiveDateTime.from_iso8601!("2024-12-23 10:21:00")
  end

  describe "La méthode Book.filter" do

    @tag :skip
    test "permet de récupérer les livres d'un auteur" do
      # --- Préparation ---
      author = make_author()
      books_author = make_books(count: 10, author: author)
      autre_aut = make_author()
      books = make_books(count: 30, author: autre_aut)
      # --- Test ---
      founds  = Book.filter(author: author)
      founds2 = Book.filter(author_id: author.id)
      # --- Vérification ---
      assert(Enum.count(founds) == 10, "On devrait avoir trouvé 10 livres par l'auteur, on en a trouvé #{Enum.count(founds)}")
      assert(Enum.count(founds2) == 10, "On devrait avoir trouvé 10 livres par l'ID de l'auteur, on en a trouvé #{Enum.count(founds2)}")
      author_book_ids = books_author |> Enum.reduce(%{}, fn b, coll -> Map.put(coll, b.id, true) end)
      (0..9)
      |> Enum.each(fn x ->
        bk = Enum.at(founds, x)
        assert(author_book_ids[bk.id], "Les livres de l'auteur (par l'auteur) devraient contenir le livre d'identifiant #{bk.id} : #{inspect books}")
        bk = Enum.at(founds2, x)
        assert(author_book_ids[bk.id], "Les livres de l'auteur (par l'identifiant) devraient contenir le livre d'identifiant #{bk.id} : #{inspect books}")
      end)
    end

    @tag :skip
    test "permet de récupérer les livres qui ont le label" do
      # --- Préparation ---
      books_ok = make_books(count: 4, label: true)
      autresbooks = make_books(count: 5, label: false)
      # --- Test ---
      founds = Book.filter(label: true)
      # --- Vérification ---
      nb = Enum.count(founds)
      assert(nb == 4, "On devrait avoir trouvé 4 livres, on en a trouvé #{nb}…")
      goods_ids = Enum.reduce(books_ok, %{}, fn bk, coll -> Map.put(coll, bk.id, true) end)
      founds |> Enum.each(fn bk ->
        assert(goods_ids[bk.id], "Le livre #{inspect bk} ne fait pas partie des livres avec label…")
      end)
    end

    @tag :skip
    test "permet de récupérer des livres par la phase courante (exacte, min ou max)" do
      books_ok = make_books(count: 5, current_phase: 20)
      make_books(count: 4, current_phase: 30)
      make_books(count: 4, current_phase: 50)
      make_books(count: 4, current_phase: 10)
      # --- Test ---
      founds = Book.filter(current_phase: 20)
      nb = Enum.count(founds)
      assert(nb == 5, "On devrait avoir trouvé 5 livres, on en a trouvé #{nb}…")
      goods_ids = Enum.reduce(books_ok, %{}, fn bk, coll -> Map.put(coll, bk.id, true) end)
      founds |> Enum.each(fn bk ->
        assert(goods_ids[bk.id], "Le livre #{inspect bk} ne fait pas partie des livres avec label…")
      end)
      # --- Test ---
      founds = Book.filter(current_phase_min: 30)
      # --- Vérification ---
      nb = Enum.count(founds)
      assert(nb == 8, "On devrait avoir trouvé 8 livres avec une phase >= à 30. On en a trouvé #{nb}…")

      # --- Test ---
      founds = Book.filter(current_phase_max: 40)
      # --- Vérification ---
      nb = Enum.count(founds)
      assert(nb == 13, "On devrait avoir trouvé 13 livres avec une phase <= à 40. On en a trouvé #{nb}…")

    end

    @tag :skip
    test "permet de récupérer les livres d'un user" do
      # Dans ce cas, c'est à peine plus compliqué car il faut retrouver
      # l'auteur qui correspond à l'user
      # --- Préparation ---
      user    = make_user()
      author  = make_author(user: user)
      books   = make_books(count: 3, author: author)
      make_books(count: 10)
      # --- Test ---
      founds = Book.filter(user: user)
      # --- Vérifications --
      nb = Enum.count(founds)
      assert(nb == 3, "On devrait avoir trouvé 3 livres du user, on en a trouvé #{nb}…")
      goodids = Enum.reduce(books, %{}, fn book, coll -> Map.put(coll, book.id, true) end)
      Enum.each(founds, fn book ->
        assert(goodids[book.id], "On aurait dû trouver le livre d'identifiant #{book.id}…")
      end)
    end

  end #/describe "Book.filter"
end