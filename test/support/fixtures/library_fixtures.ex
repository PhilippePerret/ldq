defmodule LdQ.LibraryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LdQ.Library` context.
  """

  alias LdQ.Repo

  import Ecto.Query

  import Random.Methods

  alias LdQ.Comptes
  alias LdQ.Library.{Book, UserBook}


  @doc """
  Generate a author.
  """
  def author_fixture(attrs \\ %{}) do
    # On s'assure d'avoir une Map (ou, pour le dire autrement, on 
    # permet de transmettre les données par Keyword)
    attrs = if is_list(attrs) do
      Enum.reduce(attrs, %{}, fn {k,v}, coll -> Map.put(coll, k, v) end)
    else attrs end

    user = if attrs[:user] || attrs[:user_id] do
      if attrs[:user], do: attrs[:user], else: Comptes.get_user!(attrs[:user_id])
    else 
      nil 
    end

    sexe = cond do
      attrs[:sexe]  -> attrs[:sexe]
      is_nil(user)  -> random_sexe()
      true          -> user.sexe
    end

    {:ok, author} =
      Map.merge(%{
        firstname:  random_firstname(sexe),
        lastname:   random_lastname(),
        sexe:       sexe,
        email:      "author#{uniq_int()}@example.com",
        birthyear:  Enum.random((1960..2010)),
        user_id:    user && user.id
      }, attrs)
      |> LdQ.Library.create_author()

    author
  end
  def make_author(attrs \\ %{}), do: author_fixture(attrs)


  @doc """
  Produit un livre au hasard

  @param {Map|Keyword} attrs  Attributs à employer (note : on la transforme tout de suite en Keyword)
    :title          {String}    Titre du livre
    :pitch          {String}    Pitch du livre
    :isbn           {String}    ISBN
    :publisher      {Publisher} Éditeur
    :publisher_id   {Binary}    ID de l'éditeur
    :url_command    {String}    URL de commande
    :label          {Boolean}   Pour savoir si le label est affecté ou non
                                Note : si c'est True et qu'aucune valeur de phase n'est précisée, on met une valeur >= 82
                                si c'est False et qu'aucune valeur de phase n'est précisée, on met une valeur >= 37
    :author         {Author}    Auteur du livre
    :author_id      {Binary}    ID de l'auteur du livre
    :current_phase  {Integer}   Phase courante exacte du livre
    :cur_phase_min  {Integer}   Phase courante minimale (comprise)
    :cur_phase_max  {Integer}   Phase courante maximale (comprise)
    :parrain_id     {Binary}    Le parrain du livre

  """
  def book_fixture(attrs \\ []) do
    
    attrs = if is_map(attrs) do
      Map.to_list(attrs)
    else attrs end

    author_id = if attrs[:author] || attrs[:author_id] do
      attrs[:author_id] || attrs[:author].id
    else
      make_author().id
    end
    attrs = Keyword.delete(attrs, :author)

    attrs = case attrs[:label] do
      nil -> attrs
      true ->
        if attrs[:current_phase] || attrs[:current_phase_min] do
          (attrs[:current_phase] || attrs[:current_phase_min]) >= 82 || raise("phase minimale mal définie si le livre doit avoir le label") 
          attrs
        else
          attrs ++ [current_phase_min: 82]
        end
      false ->
        if attrs[:current_phase] || attrs[:current_phase_min] do
          (attrs[:current_phase] || attrs[:current_phase_min]) >= 37 || raise("phase minimale mal définie si label doit avoir été refusé au livre") 
          attrs
        else
          attrs ++ [current_phase_min: 37]
        end
      end


    current_phase = cond do
      attrs[:current_phase] ->
        cond do
          is_integer(attrs[:current_phase]) -> attrs[:current_phase]
          is_struct(attrs[:current_phase], Range) ->
            Enum.random(attrs[:current_phase])
          is_list(attrs[:current_phase]) ->
            Enum.random(attrs[:current_phase])
        end
      attrs[:current_phase_min] ->
        random_book_phase({:min, attrs[:current_phase_min]})
      attrs[:current_phase_max] ->
        random_book_phase({:min, attrs[:current_phase_max]})
      true ->
        random_book_phase()
      end
    attrs = Keyword.delete(attrs, :current_phase)

    parrain_id = cond do
      attrs[:parrain] -> attrs[:parrain].id
      attrs[:parrain_id] -> attrs[:parrain_id]
      current_phase >= 18 ->
        LdQ.ComptesFixtures.get_membre().id
      true -> nil
    end
    attrs = Keyword.delete(attrs, :parrain)
    attrs = Keyword.delete(attrs, :parrain_id)

    publisher_id = if attrs[:publisher_id] || attrs[:publisher] do
      attrs[:publisher_id] || attrs[:publisher].id
    else
      publisher = if Enum.random((1..40)) > 20 do
        make_publisher()
      else
        random_publisher()
      end
      publisher.id
    end
    attrs = Keyword.delete(attrs, :publisher)

    label_year = if attrs[:label] do
      current_year = NaiveDateTime.utc_now().year
      attrs[:label_year] || Enum.random((2000..current_year))
    else attrs[:label_year] end

    url_command = attrs[:url_command] || random_url_command()

    default_attrs = %{
      title:          attrs[:title] || random_title(),
      isbn:           attrs[:isbn] || random_isbn(),
      author_id:      author_id,
      parrain_id:     parrain_id,
      publisher_id:   publisher_id,
      current_phase:  current_phase,
      label:          attrs[:label],
      label_year:     label_year,
      url_command:    url_command,
      transmitted:    attrs[:transmitted] === false || attrs[:transmitted] || true, 
      submitted_at:   attrs[:submitted_at] || random_time(:before, Enum.random(1000..100000))
    }

    # Si les attrs ont été fournis par Keyword, on les transforme en
    # Map pour pouvoir merger
    attrs = if is_list(attrs) do
      # attrs |> Enum.reduce(%{}, fn {k, v}, coll -> Map.put(coll, k, v) end)
      Map.to_list(default_attrs) ++ attrs
    else 
      attrs = Map.merge(default_attrs, attrs)
    end
    
    book = LdQ.Library.Book.save(attrs)
    unless is_struct(book, LdQ.Library.Book) do
      raise "Une erreur est survenue à la construction du livre : #{inspect book}"
    end
    book
  end
  def make_book(attrs \\ []), do: book_fixture(attrs)

  @doc """
  Pour faire plusieurs livres (10 par défaut)

  @param {Keyword|Map} attrs Les attributs à prendre en compte
    :count          {Integer}   Nombre de livres à faire
    Pour les autres propriétés, voir book_fixture
  
  @return {List of Book} Liste des livres créés
  """
  def make_books(attrs \\ []) do
    count = attrs[:count] || 10
    (1..count)
    |> Enum.map(fn x -> make_book(attrs) end)
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

  @doc """
  Retourne une phase au hasard

  @param {Duplet|nil} condition
    {:max, <valeur max comprise>}
    {:min, <valeur min comprise>}
    nil => toutes les phases possibles
  """
  def random_book_phase(condition \\ nil) do
    Book.book_phases() 
    |> Map.keys() 
    |> Enum.filter(fn bp ->
      case condition do
        nil -> true
        {:max, value} -> bp <= value
        {:min, value} -> bp >= value
      end
    end)
    |> Enum.random()
  end


  @doc """
  Retourne une URL de commande
  Noter qu'il faut qu'elle soit valide seulement en mode production
  et en mode développement.
  """
  def random_url_command(base \\ "modules") do
    "https://www.atelier-icare.net/"
  end

end
