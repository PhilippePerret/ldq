defmodule LdQ.Library.Book do
  use Ecto.Schema
  import Ecto.Query
  # import Ecto.Changeset
  alias LdQ.Repo

  alias LdQ.Comptes
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
    field :submitted_at, :naive_datetime # pour savoir quand l'administrateur a validé la candidature
    field :evaluated_at, :naive_datetime
    field :label_grade, :integer
    field :rating, :integer
    field :readers_rating, :integer
    field :readers_count, :integer

    # --- Appartenance ---
    belongs_to :parrain,    User # l'user qui s'en occupe
    belongs_to :publisher,  Lib.Publisher
    belongs_to :author,     Lib.Author

    timestamps(type: :utc_datetime)
  end

  # Tous les champs qu'on peut trouver dans les formulairespour les
  # livres.
  @fields_data %{
    # Note 1 : Inutile d'indiquer si la propriété doit être validée : 
    # l'existence seule d'une fonction `validate(<key>, ...)' fait 
    # qu'il y a validation de la propriété
    "author_id"       => %{type: :author},
    "current_phase"   => %{type: :integer},
    "evaluated_at"    => %{type: :datetime},
    "id"              => %{type: :string},
    "isbn"            => %{type: :string},
    "label"           => %{type: :boolean},
    "label_grade"     => %{type: :integer},
    "label_year"      => %{type: :year},
    "pitch"           => %{type: :string},
    "parrain_id"      => %{type: :user},
    "pre_version_id"  => %{type: :string},
    "published_at"    => %{type: :date},
    "publisher_id"    => %{type: :publisher},
    "rating"          => %{type: :integer},
    "readers_rating"  => %{type: :integer},
    "readers_count"   => %{type: :integer},
    "submitted_at"    => %{type: :datetime}, # naive date time
    "subtitle"        => %{type: :string},
    "title"           => %{type: :string},
    "transmitted"     => %{type: :boolean},
    "url_command"     => %{type: :string}
  }
  def fields_data, do: @fields_data

  # === FONCTIONS DE RÉCUPÉRATION ===

  @min_fields [:title, :author, :isbn]

  def get_all(_fields) do
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
  def get(b, d \\ @min_fields)
  # Récupère toutes les valeurs d'un coup
  def get(book_id, :all) do
    Repo.get!(__MODULE__, book_id)
    |> Repo.preload([:author, :publisher, :parrain])
  end
  # Récupère seulement les valeurs des champs +fields+
  # @param {Binary} book_id Identifiant du livre
  # @param {List of Atoms} fields List des champs à relevér. 
  #   Note 1 : le champ :id sera toujours ajouté
  #   Note 2 : Si +fields+ contient :author, :publisher ou :parrain, ces structures seront aussi ajoutées.
  def get(book_id, fields) do
    # IO.inspect(book_id, label: "BOOK_ID")
    # IO.inspect(fields, label: "FIELDS")

    # On met toujours la propriété :id
    fields = if Enum.member?(fields, :id) do fields else
      List.insert_at(fields, 0, :id)
    end
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

    book = add_foreign_properties(book, fields)

    # On ajoute toutes les évaluations si c'est nécessaire
    if Enum.empty?(dfields.foreigners) do
      book
    else
      Map.merge(book, dfields.foreigners)
    end
  end

  @doc """
  Ajoute au livre +book+ les propriétés contenues dans +fields+ et 
  le retourne.

  @param {Book} book Le livre auquel il faut ajouter les propriétés
  @params {List of Atoms} Les champs à charger dans le livre

  @return {Book} Le livre augmenté des propriétés voulues
  """
  def add(book, fields) when is_struct(book, __MODULE__) and is_list(fields) do
    surbook = get(book.id, fields)
    Map.merge(book, surbook)
  end

  @doc """
  Ajoute à +book+ {Book} les structures étrangères en fonction de
  +fields+, pour le moment peut ajouter l'auteur du livre, son
  éditeur et son parrain

  @param {Book} book La structure du livre
  @param {List} fields Liste des champs qui peut contenir, pour cette fonction, :author, :parrain ou :publisher
  """
  def add_foreign_properties(book, fields) do
    book =
      if Enum.member?(fields, :author) && Map.get(book, :author_id) do
        Map.put(book, :author, Lib.get_author!(book.author_id))
      else book end
    book = 
      if Enum.member?(fields, :publisher) && Map.get(book, :publisher_id) do
        Map.put(book, :publisher, Lib.get_publisher!(book.publisher_id))
      else book end
    book =
      if Enum.member?(fields, :parrain) && Map.get(book, :parrain_id) do
        Map.put(book, :parrain, Comptes.get_user!(book.parrain_id))
      else book end

    book
  end

  # === FONCTIONS D'ENREGISTREMENT ===


  @doc """

  @param {Map} attrs  Paramètres pour enregistrer le livre
    Les clés sont impérativement des {String} comme on peut en recevoir d'un formulaire
    Les valeurs sont obligatoirement des duplets (tuplets de 2) dont le premier et la
    valeur existante (relevée) et la seconde est la valeur nouvelle/modifiée

  @return {Map} Une table contenant :
    :book_id    L'identifiant du livre (à nil si nouveau)
    :invalid    Liste des erreurs rencontrées. Chaque élément est un tuplet {"key", "erreur"}
    :changed    Keyword liste des changements à enregistrer. Map pour une création, Keyword pour un update
    :changes_map  {List}  Liste des changements, pour s'en servir en cas d'erreur, puisque c'est toujours une liste, contrairement à :changed qui est une chose à la création et une autre à l'update. 
                          Noter que le format de :changes (liste de duplets) est le même que :invalid, pour utilisation dans les formulaires.
    :unchanged  {Map} Table des non changements
  """
  def setchange(attrs) do
    Enum.reduce(attrs, %{book_id: nil, changes_map: [], changed: [], invalid: [], unchanged: [], attrs: attrs}, fn {key, dup_or_string}, set ->
      is_unknown_key = is_nil(@fields_data[key])
      {init_value, new_value} =
        cond do
          is_unknown_key -> {nil, nil}
          is_binary(dup_or_string) -> {nil, dup_or_string}
          is_tuple(dup_or_string)  -> dup_or_string
          true -> raise "La donnée transmise à setchange est mauvaise (#{inspect dup_or_string}). Il faut transmettre soit un string soit un duplet {init-value, new-value}"
        end
      # On normalise la valeur dans set.attrs aussi car on en aura
      # besoin dans les validations
      set =
        if is_unknown_key do set else
          attrs = set.attrs
          attrs = %{attrs | key => {init_value, new_value} }
          %{set | attrs: attrs}
        end

      cond do
        is_unknown_key -> set
        key == "id" -> %{set | book_id: new_value}
        @fields_data[key] ->
          setchange_known_key(key, init_value, new_value, set)
          # |> IO.inspect(label: "\nSET tourné par key #{inspect key}")
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

  @return {Map} Retourne le +set+ avec les nouveaux résultats
  """
  def setchange_known_key(key, ival, nval, set) do
    nval = if is_binary(nval), do: String.trim(nval), else: nval
    {ival, nval} = cast_values(key, ival, nval)
    if ival != nval do
      # C'est une propriété persistante du livre et elle a changé
      case validate(key, ival, nval, set) do
      :ok -> 
        akey = String.to_atom(key)
        # Les modifications qui peuvent être entraînées par des
        # modifications de données validées
        set = on_change(akey, nval, set)
        # IO.puts "Ajout de la propriété #{inspect akey} de valeur #{inspect nval}"
        add_changed_value(akey, nval, set)
      {:error, error} ->
        %{set | invalid: set.invalid ++ [{key, error}]}
      end
    else
      # Valeur inchangée
      %{set | unchanged: set.unchanged ++ [{key, ival}]}
      # cond do
      #   is_map(set.unchanged) -> 
      #     %{set | unchanged: Map.put(set.unchanged, key, ival)}
      #   true -> 
      #     %{set | unchanged: set.unchanged ++ [{key, ival}]}
      # end
    end
  end

  @doc """
  Pour ajouter une valeur à changer dans le setchange. Cette valeur
  est ajoutée à la table qui sera transmise à insert_all ou 
  update_all en fonction du fait qu'il s'agit d'un changement ou
  d'une création

  @param {Atom} key La clé atomique du champ
  @param {Any} value La valeur quelconque du champ
  @param {Map} set Le setchange véhiculant toutes les informations sur le traitement d'enregistrement.

  @return {Map} le setchange actualisé
  """
  def add_changed_value(key, value, set) do
    Map.merge(set, %{
      changed: set.changed ++ [{key, value}],
      changes_map: set.changes_map ++ [{"#{key}", value}]
    })
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
        {_nb, error} = update(bookset)
        Map.put(bookset, :error, error)
      end
    else
      bookset
    end
  end
  # Actualisation, en fait
  def save(book, attrs) do
    attrs = Map.put(attrs, "id", {nil, book.id})
    bookset = save(attrs)
    if is_nil(bookset.error) do
      # Quand l'actualisation s'est bien passée, on doit mettre les
      # nouvelles valeurs dans le livre
      bookset.changed
      |> Enum.reduce(book, fn {key, value}, bk ->
        %{bk | key => value}
      end)
    else
      raise bookset.error
    end
  end
  
  def create(bookset) do
    # values = Map.merge(bookset.changed, %{
    #   inserted_at:  now_without_msec(),
    #   updated_at:   now_without_msec()
    # })
    values = bookset.changed ++ [
      {:inserted_at, now_without_msec()}, 
      {:updated_at, now_without_msec()}
    ]
    # IO.inspect(values, label: "\nVALEURS INJECTÉES")
    Repo.insert_all(__MODULE__, [values], returning: true)
  end
  def update(bookset) do
    values = bookset.changed ++ [{:updated_at, now_without_msec()}]
    from(b in __MODULE__, where: b.id == ^bookset.book_id)
    |> Repo.update_all(set: values)
    # |> IO.inspect(label: "FIN D'UPDATE")
  end

  def now_without_msec do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end

  # === FONCTIONS DE CHANGEMENT ===

  def on_change(:label, nval, set) do
    if nval == true do
      if set.attrs["label_year"] do set else
        add_changed_value(:label_year, Date.utc_today().year, set)
      end
    else
      # Quand le label est mis à false (retiré exceptionnellement)
      add_changed_value(:label_year, nil, set)
    end
  end
  def on_change(_k, _v, set), do: set

  # === FONCTIONS DE VALIDATION ===
  #
  # Rappel : On ne vient dans ces fonctions QUE si la valeur a chan-
  # gé, dans tout autre cas, on n'en a pas besoin.

  def validate("author_id", _ival, nval, _set) do
    cond do
      is_nil(nval)  -> :ok
      nval == ""    -> :ok
      Lib.get_author!(nval) -> :ok
      true          -> {:error, "Author #{nval} inconnu…"}
    end
  end

  def validate("current_phase", ival, nval, _set) do
    # La nouvelle phase doit obligatoirement être supérieur à 
    # la précédente
    cond do
      is_nil(ival)  -> :ok
      nval > ival   -> :ok
      nval < ival   -> {:error, "La nouvelle phase courante (#{nval}) devrait être supérieure à la phase précédente (#{ival})"}
    end
  end

  def validate("isbn", _ival, nval, _set) do
    len = String.replace(nval, "-", "") |> String.length()
    cond do
      len == 10 -> :ok
      len == 13 -> :ok
      true -> {:error, "L'ISBN doit faire soit 10 soit 13 caractère (il en fait #{len})"}
    end
  end
  def validate("label", _ival, _nval, _set) do
    :ok
  end
  def validate("label_year", _ival, nval, set) do
    # Pour qu'une année de label soit définie, il faut que le label 
    # ait été ou soit attribué ce coup-ci
    # Dans tous les cas, on cherche déjà dans +set+ pour voir si :label
    # est mis à true. Si c'est le cas, tout est bon. Si :label n'est pas
    # défini et que :book_id est défini, on demande sa valeur.
    # Mais si :label n'est pas défini et que :book_id non plus, c'est un
    # problème : on essaie de créer un livre avec une année de label sans
    # définir que le livre a le label.
    # IO.inspect(set, label: "\nSET")
    if is_nil(nval) do
      :ok
    else
      label_value = if Map.get(set.attrs, "label") do
        set.attrs["label"] |> Tuple.to_list() |> Enum.at(1)
      else nil end

      cond do
        label_value == "true" -> :ok
        label_value == "false" -> {:error, "On ne peut définir une année de labélisation si le label n'est pas accordé au livre…"}
        is_nil(set.book_id) -> {:error, "On ne peut pas affecter d'année de labélisation à la création d'un livre qui ne reçoit pas le label…"}
        get(set.book_id, [:label]).label === true -> :ok
        get(set.book_id, [:label]).label === false -> {:error, "On ne peut pas définir l'année de labélisation d'un livre qui n'a pas (encore) reçu le label…"}
      end
    end
  end
  def validate("pitch", _ival, newv, _set) do
    len = String.length(newv)
    cond do
      len > 5000  -> {:error, "Le pitch est trop long (max: 5000 caractère, il en fait #{len})"}
      true        -> :ok
    end
  end
  def validate("publisher_id", _ival, nval, _set) do
    cond do
      is_nil(nval) -> :ok
      nval == ""   -> :ok
      Lib.get_publisher!(nval) -> :ok
      true -> {:error, "Éditeur #{nval} inconnu…"} 
    end
  end
  def validate("parrain_id", _ival, nval, _set) do
    # Il faut vérifier que le parrain (user) existe et qu'il fait
    # partie du comité de lecture
    cond do
      is_nil(nval)        -> :ok
      nval == ""          -> :ok
      parrain = Comptes.get_user!(nval) ->
        case User.membre?(parrain) do
          true  -> :ok
          false -> {:error, "#{parrain.name} (#{parrain.email}) n'est pas membre du comité de lecture… Il ne peut pas être parrain"}
        end
        true -> {:error, "Parrain inconnu… (user #{nval} inexistant)"}    
      end
  end

  def validate("subtitle", _ival, newv, _set) do
    len = String.length(newv)
    cond do
      len == 0 -> :ok
      len > 255 -> {:error, "Le sous-titre est trop long (255 caractères maximum, il en fait #{len})"}
      true -> :ok
    end
  end

  def validate("title", _ival, newv, _set) do
    len = String.length(newv)
    cond do
      newv == ""          -> {:error, "Il faut fournir un titre"}
      is_nil(newv)        -> {:error, "Il faut fournir un titre"}
      title_exist?(newv)  -> {:error, "Le titre “#{newv}” existe déjà"}
      len > 255           -> {:error, "Le titre est trop long (255 caractères maximum)"}
      true                -> :ok
    end
  end
  def validate("url_command", _ival, newv, _set) do
    cond do
      String.replace(newv, " ", "") != newv -> {:error, "Une URL (de commande) ne devrait pas contenir d'espaces"}
      !String.match?(newv, ~r/^https?\:\/\//) -> {:error, "L'URL de commande #{inspect newv} n'est pas une URL valide (elle devrait commencer par http(s)://)"}
      true ->
        # {retour, 0} = System.cmd("cUrl", [newv])
        {http_code, 0} = System.cmd("curl", ["-s", "-o", "/dev/null", "-w", "%{http_code}", newv])
        http_code = String.to_integer(http_code)
        cond do
          http_code > 400   -> {:error, "L'URL de commande est une URL qui ne conduit nulle part" }
          http_code == 200 -> :ok
          http_code >= 300 && http_code <= 310 -> :ok
        end
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
  defp cast_v(:integer, value) do
    if is_binary(value) do
      String.to_integer(value)
    else value end
  end
  defp cast_v(:string,    value), do: value
  defp cast_v(:boolean, value) do
    if is_binary(value) do
      value == "true"
    else value end
  end
  defp cast_v(:datetime, value) do
    if is_binary(value) do
      NaiveDateTime.from_iso8601!(value)
      |> NaiveDateTime.truncate(:second)
    else value end
  end
  defp cast_v(:date, value) do
    if is_binary(value) do
      Date.from_iso8601!(value)
    else value end
  end
  defp cast_v(:user,      value), do: value
  defp cast_v(:author,    value), do: value
  defp cast_v(:publisher, value), do: value
  defp cast_v(:year, value) do
    if is_binary(value) do
      value = if String.length(value) == 2, do: "20#{value}", else: value
      String.to_integer(value)
    else value end
  end
  defp cast_v(_anytype, value), do: value
end
