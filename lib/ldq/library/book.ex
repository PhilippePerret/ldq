defmodule LdQ.Library.Book do
  use Ecto.Schema
  import Ecto.Query
  alias LdQ.Repo

  alias LdQ.Comptes
  alias LdQ.Comptes.{User, Membre}
  alias LdQ.Evaluation.UserBook
  alias LdQ.Library, as: Lib

  @min_fields [:id, :title, :author, :isbn]

  @doc """
  @api
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
  def get(book_id, fields) when is_list(fields) do
    get_book_with_fields(book_id, fields)
  end

  @doc """
  Établit et retourne la liste des livres non évalués, pour un collè-
  ge donné.
  On les reconnait simplement à leur phase courante. Entre 20 (mise
  en évaluation par l'administrateur) et 30 (collège 1 atteint) pour
  le premier collège etc.
    PREMIER COLLÈGE:    entre 20 et 29
    SECOND COLLÈGE:     entre 40 et 49
    TROISIÈME COLLÈGE:  entre 60 et 69
    (ce sont les valeurs que le livre peut avoir)

  @param {Integer} college (1, 2 ou 3)
  @param {Keyword} options Permet de préciser la recherche :
    :fields   Les champs à retourner
    :by       {Membre} Il ne faut pas prendre les livres déjà évalués (en cours d'évaluation) par ce membre
  """
  
  def get_not_evaluated(college, options \\ nil) do
    phase_min = college * 20
    phase_max = phase_min + 9
    fields = options[:fields] || [:title, :author, :subtitle, :inserted_at]
    filter([current_phase_min: phase_min, current_phase_max: phase_max, not_evaluated_by: options[:by]], fields)
  end

  @doc """
  @api 
  Établit et retourne la liste des livres évalués par le +membre+ 
  avec les options +options

  TODO Pouvoir relever aussi le nombre de membres qui évaluent le 
  livre (ou fonction séparée ?)

  @param {Membre} membre Le membre du comité de lecture
  @param {Keyword} options Liste des options, donc :
    :type    Si :current, on s'intéresse seulement aux livres en cours d'évaluation, i.e. sans note
              Si :all (défaut) tous les livres
  """
  def get_books_evaluated_by(membre, options \\ [type: :all]) when is_struct(membre, Membre) do
    query = from(b in __MODULE__, 
      join: ub in UserBook, on: b.id == ub.book_id, 
      where: ub.user_id == ^membre.id
      )

    query = if options[:type] == :current do
      where(query, [_b, ub], is_nil(ub.note))
    else query end

    fields = options[:fields] || @min_fields
    # Séparer les préloads des champs réels
    %{fields: fields, preloads: preloads} = 
      [:author, :publisher, :parrain]
      |> Enum.reduce(%{fields: fields, preloads: []}, fn prop, coll -> 
        if Enum.member?(fields, prop) do
          coll = %{coll | preloads: coll.preloads ++ [prop]}
          coll = %{coll | fields: List.delete(coll.fields, prop)}
          %{coll | fields: coll.fields ++ [String.to_atom("#{prop}_id")]}
          |> IO.inspect(label: "Collector")
        else coll end
      end)
    query = select(query, [b], struct(b, ^fields))

    books = Repo.all(query)
    # |> IO.inspect(label: "Livre récupérés")
    if Enum.any?(preloads) do
      books |> Repo.preload(preloads) #|> IO.inspect(label: "LIVRES AVEC PRELOAD")
    else 
      books 
    end
  end

  @doc """
  @return True si le livre +book+ peut être noté par le collège. 
  L'expression "noté par le collège" signifie que le quota de lecteur
  a été atteint et qu'on peut donc affecter une note au livre pour
  savoir s'il va passer au collège suivant (ou recevoir le label de
  lecture de qualité).

  Pour savoir si un livre est noteable, il doit avoir atteint le
  nombre de lecteur défini par LdQ.Evaluation.Number@
  """
  def noteable?(book = %_MODULE_) do
    # Déterminer le nombre requis de lecteur pour le collège courant
    # du livre
    quorum_readers_reached?(book)
  end
  def quorum_readers_reached?(book = %_MODULE_) do
    quota_readers = "nombre_evaluators_college#{book.college}" 
    |> String.to_atom |> LdQ.Evaluation.Number.nombre_for()
    nombre_readers = count_readers(book)
    nombre_readers >= quota_readers
  end

  # =============== /FIN MÉTHODES API ==================== #

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
    field :last_phase,    :integer
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
    "last_phase"      => %{type: :integer},
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

  # Les phases d'évaluation du livre
  # 
  # Elles doivent obligatoirement aller crescendo
  @book_phases %{
    0 => %{name: "Livre simplement proposé"},
    1 => %{name: "Demande d'informations supplémentaires"},
    2 => %{name: "Refusé avant soumission"},
    5 => %{name: "Accepté par l'administration"},
    10  => %{name: "Demande d'autorisation de l'auteur"},
    11  => %{name: "Refus de l'autorisation de l'auteur"},
    15  => %{name: "Acceptation de la soumission par l'auteur"},
    18  => %{name: "Désignation d'un parrain membre du comité"},
    20  => %{name: "Mis en évaluation par l'administration"},
    21  => %{name: "Premier membre du premier collège prend le livre"},
    30  => %{name: "Premier collège de membres atteint"},
    32  => %{name: "Évaluation premier collège en cours"},
    35  => %{name: "Fin évaluation premier collège"},
    37  => %{name: "REJET PREMIER COLLÈGE"},
    40  => %{name: "ACCEPTATION PREMIER COLLÈGE"},
    50  => %{name: "Deuxième collège de membres atteint"},
    52  => %{name: "Évaluation second collège en cours"},
    55  => %{name: "Fin évaluation second collège"},
    57  => %{name: "REJET SECOND COLLÈGE"},
    60  => %{name: "ACCEPTATION SECOND COLLÈGE"},
    70  => %{name: "Troisième collège de membres atteint"},
    72  => %{name: "Évaluation troisième collège en cours"},
    75  => %{name: "Fin évaluation troisième collège"},
    77  => %{name: "REJET TROISIÈME COLLÈGE"},
    80  => %{name: "ACCEPTATION TROISIÈME COLLÈGE"},
    82  => %{name: "LABEL LECTURE DE QUALITÉ ATTRIBUÉ"},
    84  => %{name: "Entrée dans les classements"},
    86  => %{name: "Mise à l'évaluation pour tout lecteur"},
    100 => %{name: "Retrait de label pour faute grave"},
    102 => %{name: "Retrait du label par décision de l'auteur"},
    104 => %{name: "Retrait du label pour autre raison"}
  }
  def book_phases, do: @book_phases

  # === FONCTIONS DE RÉCUPÉRATION ===

  @doc """
  Filtre les livres et les renvoie

  @param {Map|Keyword} filtre Le filtre à appliquer
    :author             {Author}  L'auteur du livre
    OU :author_id       {Binary}  ID de l'auteur du livre
    :label              {Boolean} Label attribué ou non
    :current_phase_min  {Integer} La phase minium (comprise)
    :current_phase_max  {Integer} La phase maximum (comprise)
    :current_phase      {Integer} La phase exacte
    :user               {User} L'user qui est l'auteur du livre
    :not_evaluated_by   {Member} Le livre ne doit pas avoir été évalué par ce membre
    :parrain_id         {Binary} Le livre doit être parrainé par ce parrain
    OU :parrain         {User} Le parrain du livre (membre du collège 3 qui s'en occupe)
  """
  def filter(filtre, fields \\ @min_fields) do

    # Dans un premier temps, si fields[:user] a été fourni, il faut
    # retrouver l'auteur qu'il est (en considérant qu'un user peut
    # avoir plusieurs authors (pseudo))
    filtre = if filtre[:user] || filtre[:user_id] do
      uid = filtre[:user_id] || filtre[:user].id
      author_ids = 
        from(w in Lib.Author, where: w.user_id == ^uid, select: w)
        |> Repo.all()
        |> Enum.map(fn author -> author.id end)
      if Enum.empty?(author_ids) do
        LdQ.Constantes.env_test? && raise("On devrait avoir trouvé des auteurs pour l'user donné (#{uid}) !")
        filtre
      else
        filtre ++ [author_id: author_ids]
      end
    else filtre end

    # === DÉBUT DE LA REQUÊTE ===

    query = from(b in __MODULE__,
      distinct: b.id,
      join: w in Lib.Author, on: b.author_id == w.id
      # left_join: ub in UserBook, on: b.id == ub.book_id
      #  left_join: p in Lib.Publisher, on: b.publisher_id == p.id,    
    )

    # - L'auteur du livre - 

    query = if filtre[:author] || filtre[:author_id] do
      author_id = filtre[:author_id] || filtre[:author].id
      if is_binary(author_id) do
        where(query, [_b, w], w.id == ^author_id)
      else
        where(query, [_b, w], w.id in ^author_id)
      end
    else query end

    # - Le parrain du livre -

    query = if filtre[:parrain_id] || filtre[:parrain] do
      parrain_id = filtre[:parrain_id] || filtre[:parrain].id
      where(query, [b, _w], b.parrain_id == ^parrain_id)
    else query end

    # - Avec label ou non -
    # (note : si le label est true, ça impose une condition sur la 
    #  phase courante si elle n'est pas définie)
    {query, filtre} = if filtre[:label] === true || filtre[:label] === false do
      query = where(query, [b, _w], b.label == ^filtre[:label])
      filtre = if filtre[:current_phase_min] do
        if filtre[:label] === true do
          filtre[:current_phase_min] >= 82 || raise("Mauvais filtre de la phase courante. Pour que le label soit attribué, il faut au moins la phase 82.")
        else
          filtre[:current_phase_min] >= 37 || raise("Mauvais filtre de la phase courante. Pour que le label soit refusé, il faut au moins la phase 37.")
        end
        filtre
      else
        if filtre[:label] === true do
          filtre ++ [current_phase_min: 82]
        else
          filtre ++ [current_phase_min: 37]
        end
      end
      {query, filtre}
    else {query, filtre} end

    # - La phase courante (exacte, min ou max) -

    query = if filtre[:current_phase] do
      where(query, [b, _w], b.current_phase == ^filtre[:current_phase])
    else query end

    query = if filtre[:current_phase_min] do
      where(query, [b, _w], b.current_phase >= ^filtre[:current_phase_min])
    else query end

    query = if filtre[:current_phase_max] do
      where(query, [b, _w], b.current_phase <= ^filtre[:current_phase_max])
    else query end

    require_author = Enum.member?(fields, :author)

    direct_fields = if require_author do
      List.delete(fields, :author)
    else fields end

    direct_fields = Enum.uniq([:id] ++ direct_fields)

    query = query |> select([b, _w], map(b, ^direct_fields))

    query = if require_author do
      select_merge(query, [_b, w], %{author_name: w.name, author_sexe: w.sexe})
    else query end

    # IO.inspect(query, label: "\nQUERY FINALE")
    # raise "pour voir"

    first_recolte = Repo.all(query)
    
    # IO.inspect(first_recolte, label: "\nPREMIÈRE RÉCOLTE")

    # Quand on doit retirer les livres évalués par un lecteur
    _seconde_recolte = 
      if filtre[:not_evaluated_by] do
        # On relève les livres évalués par le membre
        membre_id = if is_binary(filtre[:not_evaluated_by]), do: filtre[:not_evaluated_by], else: filtre[:not_evaluated_by].id
        lus_par_user = 
          from(b in __MODULE__, distinct: b.id,
          join: ub in UserBook, on: ub.book_id == b.id and ub.user_id == ^membre_id)
          |> Repo.all()
          |> Enum.reduce(%{}, fn book, coll -> 
            Map.put(coll, book.id, true)
          end)
          # |> IO.inspect(label: "\nLUS PAR USER")
        # On retire de la première récolte les livres lu par le
        # membre
        if Enum.any?(lus_par_user) do
          first_recolte
          |> Enum.reject(fn book -> lus_par_user[book.id] end)
        else
          first_recolte
        end
      else 
        first_recolte
      end


  end

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

  # Récupère seulement les valeurs des champs +fields+
  # @param {Binary} book_id Identifiant du livre
  # @param {List of Atoms} fields List des champs à relevér. 
  #   Note 1 : le champ :id sera toujours ajouté
  #   Note 2 : Si +fields+ contient :author, :publisher ou :parrain, ces structures seront aussi ajoutées.
  def get_book_with_fields(book_id, fields) do
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

  @param {Map|Keyword} attrs  Paramètres pour enregistrer le livre
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
    # On normalise +attrs+ qui peut :
    #   - être un Keyword au lieu d'une Map
    #   - avoir des clés atomique au lieu de String
    #   - avoir des valeurs nil (à supprimer)
    attrs = if is_map(attrs) do attrs else
      Enum.reduce(attrs, %{}, fn {key, v}, coll -> Map.put(coll, key, v) end)
    end
    attrs = attrs 
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.reduce(%{}, fn {k, v}, coll ->
      k = if is_atom(k), do: Atom.to_string(k), else: k
      Map.put(coll, k, v)
    end)
    Enum.reduce(attrs, %{book_id: nil, changes_map: [], changed: [], invalid: [], unchanged: [], attrs: attrs}, fn {key, duplorstr}, set ->
      is_unknown_key = is_nil(@fields_data[key])
      {init_value, new_value} =
        cond do
          is_unknown_key -> {nil, nil}
          is_binary(duplorstr) -> {nil, duplorstr}
          is_tuple(duplorstr)  -> duplorstr
          is_boolean(duplorstr) -> {nil, "#{duplorstr}"} # "true" au lieu de true
          is_integer(duplorstr) -> {nil, "#{duplorstr}"} # "12" au lieu de 12
          is_struct(duplorstr, Date) -> {nil, Date.to_iso8601(duplorstr)}
          is_struct(duplorstr, NaiveDateTime) -> {nil, NaiveDateTime.to_iso8601(duplorstr)}
          true -> raise "La donnée transmise à setchange est mauvaise (#{inspect duplorstr}). Il faut transmettre soit un string, soit un entier, une valeur booléenne, soit un duplet {init-value, new-value}"
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
  (mais pour l'update, voir la seconde fonction)

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
  # Actualisation, en fait, donc en fournissant le livre et les
  # propriétés à enregistrer
  # 
  # @param {Book} book Le livre à actualiser
  # @param {Map} attrs Les nouvelles valeurs. Attention, c'est une table avec clé et valeur, mais
  #               pour assurer la transformation, les valeurs doivent se trouver sous la forme :
  #               {<valeur actuelle>, <nouvelle valeur>}. C'est particulièrement vrai si la nouvelle
  #               valeur est Nil : %{maprop: {ancienne_valeur, nil}}
  # 
  # @return un {LdQ.Library.Book} si la sauvegarde a pu se faire, ou
  # {String} l'erreur ou les erreurs dans le cas contraire.
  def save(book, attrs) do
    # S'assurer que les clés soient en string
    attrs = 
      Enum.reduce(attrs, %{}, fn {k, v}, coll ->
        realk = if is_atom(k), do: Atom.to_string(k), else: k
        Map.put(coll, realk, v)
      end)
    attrs = Map.put(attrs, "id", {nil, book.id})
    bookset = save(attrs)
    if is_nil(bookset[:error]) do
      # Quand l'actualisation s'est bien passée, on doit mettre les
      # nouvelles valeurs dans le livre
      bookset.changed
      |> Enum.reduce(book, fn {key, value}, bk ->
        %{bk | key => value}
      end)
    else
      bookset.error
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

  def validate("last_phase", ival, nval, _set) do
    # La dernière phase, si elle n'est pas nil, doit obligatoirement :
    #   - exister
    #   - supérieure à l'ancienne dernière phase si elle est défini
    #   - inférieure obligatoirement à la phase courante TODO
    cond do
      is_nil(nval) -> :ok
      is_nil(@book_phases[nval]) -> {:error, "La dernière phase (#{nval}) doit obligatoirement exister."}
      is_nil(ival) -> :ok
      nval > ival  -> :ok
      nval < ival   -> {:error, "La nouvelle dernière phrase (#{nval}) doit être supérieure à l'ancienne dernière phase (#{ival})…"}
    end
  end

  def validate("current_phase", ival, nval, _set) do
    # La nouvelle phase, si elle est définie, doit obligatoirement :
    #   - exister
    #   - être supérieure à la précédente (vraiment ?)
    #   - être supérieure à la nouvelle phase précédente TODO
    cond do
      is_nil(nval)  -> :ok
      is_nil(@book_phases[nval]) -> {:error, "La nouvelle phase courante (#{nval}) est inconnue…"}
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
  # Warning : la méthode est utilisée aussi dans la procédure qui
  # gère l'évaluation des livres. Dans ce cas, +i_val+ et +set+ ne
  # valent rien.
  def validate("url_command", _ival, newv, _set) do
    if LdQ.Constantes.env_test? do
      # En mode test, on ne vérifie pas que ce soit une URL existante
      # et qui contient le titre du livre
      cond do
        String.replace(newv, " ", "") != newv -> {:error, "Une URL (de commande) ne devrait pas contenir d'espaces"}
        !String.match?(newv, ~r/^https?\:\/\//) -> {:error, "L'URL de commande #{inspect newv} n'est pas une URL valide (elle devrait commencer par http(s)://)"}
        true -> :ok
      end
    else
      cond do
        String.replace(newv, " ", "") != newv -> {:error, "Une URL (de commande) ne devrait pas contenir d'espaces"}
        !String.match?(newv, ~r/^https?\:\/\//) -> {:error, "L'URL de commande #{inspect newv} n'est pas une URL valide (elle devrait commencer par http(s)://)"}
        true ->
          # {retour, 0} = System.cmd("cUrl", [newv])
          {http_code, 0} = System.cmd("curl", ["-s", "-o", "/dev/null", "-w", "%{http_code}", newv])
          http_code = String.to_integer(http_code)
          cond do
            http_code > 400   -> {:error, "L'URL de commande est une URL qui ne conduit nulle part" }
            http_code == 200 -> 
              # TODO Il faudrait vérifier aussi que la page contienne le titre du
              # livre, ou/et l'ISBN, et/ou le nom de l'auteur
              :ok
            http_code >= 300 && http_code <= 310 -> :ok
          end
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
