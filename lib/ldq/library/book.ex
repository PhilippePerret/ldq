defmodule LdQ.Library.Book do
  use Ecto.Schema
  import Ecto.Query
  # import Ecto.Changeset
  alias LdQ.Repo

  alias LdQ.Comptes.User
  alias LdQ.Library, as: Lib

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "books" do
    field :title, :string
    field :pitch, :string
    # --- Spécifications ---
    field :label, :boolean, default: false
    field :isbn, :string
    field :published_at, :date
    field :subtitle, :string
    field :label_year, :integer
    field :url_command, :string
    field :pre_version_id, :binary_id
    # --- Evaluation ---
    field :transmitted, :boolean, default: false
    field :current_phase, :integer
    field :submitted_at, :naive_datetime
    field :evaluated_at, :naive_datetime
    field :label_grade, :integer
    field :rating, :integer
    field :readers_rating, :integer

    # --- Appartenance ---
    belongs_to :parrain,    User # l'user qui s'en occupe
    belongs_to :publisher,  Lib.Publisher
    belongs_to :author,     Lib.Author

    timestamps(type: :utc_datetime)
  end


  # === FONCTIONS DE RÉCUPÉRATION ===

  @min_fields [:title, :author, :isbn]

  def get_all(fields) do
    raise "Il faut que j'apprenne"
  end

  def get_all do
    from(b in __MODULE__,
     left_join: w in Lib.Author, on: b.author_id == w.id,
     left_join: p in Lib.Publisher, on: b.publisher_id == p.id,
     select: %{
      title: b.title, 
      book_title: b.title,
      author: w.name, author_sexe: w.sexe,
      pub_name: p.name, pub_address: p.address
    })
    |> Repo.all()
  end

  @doc """
  Permet de récupérer les valeurs voulues du livre.
  Note : Si on appelle sans l'argument, on retourne les valeurs minimales.

  @params {List} fields Liste des propriétés qu'on doit remonter. Note : :id est toujours implicite, inutile de le mettre.

  @return {LdQ.Library.Book} Le livre avec seulement les propriétés voulues
  """
  def get(book_id, fields \\ @min_fields) do
    IO.inspect(book_id, label: "BOOK_ID")
    IO.inspect(fields, label: "FIELDS")
    dfields =
      Enum.reduce(fields, %{fields: [], foreigners: %{}}, fn field, coll ->
        case field do
        :author       -> %{coll | fields: coll.fields ++ [:author_id]}
        :publisher    -> %{coll | fields: coll.fields ++ [:publisher_id]}
        :parrain      -> %{coll | fields: coll.fields ++ [:parrain_id]}
        :evaluations  ->
          coll # pour le moment TODO Ensuite, il faudra relever toutes les évaluations du livre et les mettre dans foreigners avec la clé :evaluations
        _ -> %{coll | fields: coll.fields ++ [field]}
        end
      end)
    book = 
      from(b in __MODULE__, where: b.id == ^book_id, select: ^dfields.fields)
      |> Repo.one!()

    book =
      if Enum.member?(fields, :author) && book.author_id do
        Map.put(book, :author, Lib.get_author!(book.author_id))
      else book end
    book = 
      if Enum.member?(fields, :publisher) && book.publisher_id do
        Map.put(book, :publisher, Lib.get_publisher!(book.publisher_id))
      else book end
    book =
      if Enum.member?(fields, :parrain) && book.parrain_id do
        Map.put(book, :parrain, Comptes.get_user!(book.parrain_id))
      else book end

    Map.merge(book, dfields.foreigners)
  end

  # === FONCTIONS D'ENREGISTREMENT ===

  @fields_data %{
    # Note 1 : Inutile d'indiquer si la propriété doit être validée : 
    # l'existence seule d'une fonction `validate(<key>, ...)' fait 
    # qu'il y a validation de la propriété
    "id"              => %{type: :string},
    "title"           => %{type: :string},
    "pitch"           => %{type: :string},
    "isbn"            => %{type: :string},
    "author_id"       => %{type: :author},
    "parrain_id"      => %{type: :user},
    "current_phase"   => %{type: :integer},
    "label"           => %{type: :boolean},
    "rating"          => %{type: :integer}
    # TODO Poursuivre avec les autres propriétés
  }

  @doc """

  @param {Map} attrs  Paramètres pour enregistrer le livre
    Les clés sont impérativement des {String} comme on peut en recevoir d'un formulaire
    Les valeurs sont obligatoirement des duplets (tuplets de 2) dont le premier et la
    valeur existante (relevée) et la seconde est la valeur nouvelle/modifiée

  @return {Map} Une table contenant :
    :book_id    L'identifiant du livre (à nil si nouveau)
    :invalid    Liste des erreurs rencontrées. Chaque élément est un tuplet {"key", "erreur"}
    :changed    Map ou Keyword liste des changements à enregistrer. Map pour une création, Keyword pour un update
    :changes_map  {List}  Liste des changements, pour s'en servir en cas d'erreur, puisque c'est toujours une liste, contrairement à :changed qui est une chose à la création et une autre à l'update. 
                          Noter que le format de :changes (liste de duplets) est le même que :invalid, pour utilisation dans les formulaires.
    :unchanged  {Map} Table des non changements
  """
  def setchange(attrs) do
    operation = if attrs["id"], do: :update, else: :create
    # Si c'est une création, on doit transmettre les valeurs avec une
    # map, alors que si c'est une actualisation, on doit transmettre 
    # une liste de tuples.
    changed   = if operation == :update, do: [], else: %{}
    Enum.reduce(attrs, %{book_id: nil, changes_map: [], changed: changed, invalid: [], unchanged: []}, fn {key, dup_or_string}, set ->
      {init_value, new_value} =
        cond do
          is_binary(dup_or_string) -> {nil, dup_or_string}
          {a, b} = (dup_or_string) -> dup_or_string
          true -> raise "La donnée transmise à sechange est mauvaise (#{inspect dup_or_string}). Il faut transmettre soit un string soit un duplet {init-value, new-value}"
        end
      cond do
      key == "id" -> %{set | book_id: init_value}
      @fields_data[key] ->
        setchange_known_key(key, init_value, new_value, set, operation)
      true -> 
        set 
      end
    end)
  end

  @doc """
  @param {String} key La clé (champ) du livre
  @param {String} ival  Pour "initial-value" La valeur initiale (quand c'est une modification, pour savoir si la valeur a changé)
  @param {String} nval  Pour "new-value", la nouvelle valeur du champ
  @param {Map}    set La table contenant l'état de la transaction
  @param {Atom}   operation L'opération, soit :update, soit :create
  """
  def setchange_known_key(key, ival, nval, set, operation) do
    nval = String.trim(nval)
    {ival, nval} = cast_values(key, ival, nval)
    if ival != nval do
      # C'est une propriété persistante du livre et elle a changé
      case validate(key, ival, nval, set) do
      :ok -> 
        akey = String.to_atom(key)
        case operation  do
          :update -> 
            Map.merge(set, %{
              changed: set.changed ++ [{akey, nval}],
              changes_map: set.changes_map ++ [{key, nval}]
            })
          :create ->
            Map.merge(set, %{
              changed: Map.put(set.changed, akey, nval),
              changes_map: set.changes_map ++ [{key, nval}]
            })
        end
      {:error, error} ->
        %{set | invalid: set.invalid ++ [{key, error}]}
      end
    else
      # Valeur inchangée
      %{set | unchanged: set.unchanged ++ [{key, ival}]}
    end
  end

  @doc """
  @api
  Pour enregistrer le livre, aussi bien à la création qu'à l'update

  @param {Map} attrs Une table d'attributs quelconques dont les clés 
  sont toutes string (venant d'un formulaire)

  @return {Book}  En cas de succès, 
          {Map}   Le bookset en cas d'erreur, contenant :invalid (liste des erreurs) et :changed (liste des changements)
  """
  def save(attrs) do
    bookset = setchange(attrs)
    # |> IO.inspect(label: "\nBOOKSET dans save (avec #{inspect attrs["title"]})")
    if Enum.empty?(bookset.invalid) do    
      case bookset.book_id do
      nil -> 
        {_nb, books} = create(bookset) 
        books |> Enum.at(0)
      _   -> 
        {_nb, books} = update(bookset)
        books
      end
    else
      bookset
    end
  end
  def create(bookset) do
    values = Map.merge(bookset.changed, %{
      inserted_at:  now_without_msec(),
      updated_at:   now_without_msec()
    })
    Repo.insert_all(__MODULE__, [values], returning: [:id, :title])
  end
  def update(bookset) do
    values = bookset.changed ++ [{:updated_at, now_without_msec()}]
    from(b in __MODULE__, where: b.id == ^bookset.book_id)
    |> Repo.update_all(set: values)
  end

  def now_without_msec do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end

  # === FONCTIONS DE VALIDATION ===
  #
  # Rappel : On ne vient dans ces fonctions QUE si la valeur a chan-
  # gé, dans tout autre cas, on n'en a pas besoin.

  def validate("title", initv, newv, set) do
    len = String.length(newv)
    cond do
      newv == ""          -> {:error, "Il faut fournir un titre"}
      is_nil(newv)        -> {:error, "Il faut fournir un titre"}
      title_exist?(newv)  -> {:error, "Le titre “#{newv}” existe déjà"}
      len > 255           -> {:error, "Le titre est trop long (255 caractères maximum)"}
      true                -> :ok
    end
  end
  def validate("pitch", init_value, newv, set) do
    len = String.length(newv)
    cond do
      len > 5000  -> {:error, "Le pitch est trop long (max: 5000 caractère, il en fait #{len})"}
      true        -> :ok
    end
  end
  def validate("isbn", ival, nval, set) do
    len = String.replace(nval, "-", "") |> String.length()
    cond do
      len == 10 -> :ok
      len == 13 -> :ok
      true -> {:error, "L'ISBN doit faire soit 10 soit 13 caractère (il en fait #{len})"}
    end
  end
  def validate("author_id", ival, nval, set) do
    cond do
      is_nil(nval)  -> :ok
      nval == ""    -> :ok
      Lib.get_author!(nval) -> :ok
      true          -> {:error, "Author #{nval} inconnu…"}
    end
  end
  def validate("parrain_id", ival, nval, set) do
    # Il faut vérifier que le parrain (user) existe et qu'il fait
    # partie du comité de lecture
    parrain = User.get!(nval)
    cond do
      is_nil(nval)        -> :ok
      nval == ""          -> :ok
      parrain = User.get!(nval) ->
        case User.member?(parrain) do
          true  -> :ok
          false -> {:error, "#{parrain.name} (#{parrain.email}) n'est pas membre du comité de lecture… Il ne peut pas être parrain"}
        end
      true -> {:error, "Parrain inconnu… (user #{nval} inexistant)"}    
    end
  end
  def validate(_unvalidated_key, _i, _n, _s), do: :ok


  # === Méthodes de check ===

  def title_exist?(title) do
    Repo.exists?(from b in __MODULE__, where: b.title == ^title)
  end

  # === Méthodes utilitaires ===
  
  # Transformation de la valeur venant du champ (donc toujours en
  # string) en valeur réelle propre à la table.
  defp cast_values(key, ivalue, nvalue) do
    type = @fields_data[key].type
    {cast_v(type, ivalue), cast_v(type, nvalue)}
  end
  defp cast_v(:integer, value), do: String.to_integer(value)
  defp cast_v(:string,  value), do: value
  defp cast_v(:boolean, value), do: value == "true" # à vérifier parce qu'elle est peut-être transformée en true, vraiment
  defp cast_v(:user,    value), do: value
  defp cast_v(:author, value), do: value

end
