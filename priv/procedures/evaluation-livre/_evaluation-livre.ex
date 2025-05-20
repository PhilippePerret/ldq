defmodule LdQ.Procedure.PropositionLivre do
  @moduledoc """
  Cette procédure commence avec la proposition d'un livre pour le
  label Lecture de Qualité et se termine par son attribution ou non
  du label suivi de son évaluation au fil du temps par les lecteurs.

  Il s'agit donc de la vie totale d'un livre au sein du label.

  """
  use LdQWeb.Procedure
  
  import LdQ.Site.PageHelpers # notamment pour ldq_label

  alias LdQ.Library, as: Lib
  alias LdQ.Library.Book

  def proc_name, do: "Évaluation d’un livre"

  @steps [
    %{name: "Soumission du livre", fun: :proposition_livre, admin_required: false, owner_required: false},
    %{name: "Soumission du livre par l'ISBN", fun: :submit_book_with_isbn, admin_required: false, owner_required: true},
    %{name: "Soumission du livre par formulaire", fun: :submit_book_with_form, admin_required: false, owner_required: true},
    %{name: "Consigner le livre pour évaluation", fun: :consigner_le_livre, admin_required: false, owner_required: true},
    %{name: "Confirmation de la soumission par l'auteur", fun: :auteur_confirme_soumission_livre, admin_required: false, owner_required: false},
  
    %{name: "Suppression complète du livre", fun: :complete_book_remove, admin_required: true, owner_required: false}
  ]
  def steps, do: @steps


  @doc """
  Fonction qui détermine (en fonction de la procédure) les données à
  enregistrer dans la table
  """
  def procedure_attributes(params) do
    user = params.user
    %{
      proc_dim:     "evaluation-livre",
      owner_type:   "user",
      owner_id:     user.id,
      steps_done:   ["create"],
      current_step: "create",
      next_step:    "proposition_livre",
      data: %{
        user_id:    user.id,
        user_mail:  user.email,
        folder:     __DIR__
      }
    }
  end

  @doc """
  Méthode propre à chaque procédure qui permet d'injecter 
  systématiquement des propriétés volatiles dans la table de la
  procédure qui circule de fonction en fonction.
  """
  def defaultize_procedure(proc) do
    # Ajout du livre s'il est défini
    if Map.get(proc.data, "book_id") do
      Map.put(proc, :book, Book.get(proc.data["book_id"]))
    else 
      proc
    end
  end


  @doc """
  Fonction appelée pour permettre à l'utilisateur de proposer un
  livre au label. Elle lui présente la chose
  """
  def proposition_livre(procedure) do
    user = procedure.user

    form_with_isbn = Html.Form.formate(%Html.Form{
      id: "form-submit-with-isbn",
      prefix: "by_isbn",
      action: "/proc/#{procedure.id}",
      method: "POST",
      captcha: true,
      fields: [
        %{type: :hidden, strict_name: "nstep", value: "submit_book_with_isbn"},
        %{type: :text, name: "isbn", label: "ISBN du livre", required: true},
        %{type: :checkbox, name: "is_author", value: "yes", label: "Je suis l'aut#{fem(:rice, user)} du livre"}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre par ISBN"}
      ]
    })

    form_with_form = Html.Form.formate(%Html.Form{
      id: "form-submit-with-form",
      prefix: "by_form",
      action: "/proc/#{procedure.id}",
      method: "POST",
      captcha: true,
      fields: [
        %{type: :hidden, strict_name: "nstep", value: "submit_book_with_form"},
        %{type: :checkbox, name: "is_author", value: "yes", label: "Je suis l'aut#{fem(:rice, user)} du livre"}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre par formulaire"}
      ]

    })
    """
    <p>#{user.name}, pour proposer un livre, vous devez en être l'autrice ou l'auteur OU 
    être en possession des informations sur l'auteur, à minima connaitre son
    adresse de courriel afin que nous puissions le contacter.</p>

    <div class="colonnes">
      <div class="col1">#{form_with_isbn}</div>
      <div class="col2">#{form_with_form}</div>
    </div>
    """
  end

  # @isbn_providers [
  #   {"ISBN Search", "https://isbnsearch.org/isbn/__ISBN__", :parse_from_isbn_search},
  #   {"google books", "https://www.googleapis.com/books/v1/volumes?q=isbn:__ISBN__", :none},
  #   {"open library", "https://openlibrary.org/api/books?bibkeys=ISBN:__ISBN__&format=json&jscmd=details", :none},
  #   {"word cat", "http://xisbn.worldcat.org/webservices/xid/isbn/__ISBN__?method=getMetadata&fl=*&format=json", :none},
  #   {"Chasse aux livres", "https://www.chasse-aux-livres.fr/recherche-par-isbn/search?catalog=fr&query=__ISBN__", :parse_from_chasse_aux_livres}
  #   # Le meilleur mais Par abonnement {"ISBN Db", "https://api2.isbndb.com/book/__ISBN__"}
  # ]

  @doc """
  Soumission du livre par son ISBN. En fait, la fonction relève les
  informations qu'elle peut trouver sur le net et appelle la fonction
  normale qui utilise un formulaire pour le peupler.
  """
  def submit_book_with_isbn(procedure) do
    case check_captcha(procedure, "by_isbn") do
    :ok -> proceed_submit_book_with_isbn(procedure)
    {:error, message} -> message
    end
  end

  @book_first_data %{
    title: nil, 
    pitch: nil, 
    author_firstname: nil,
    author_lastname: nil,
    author_email: nil,
    isbn: nil,
    publisher_name: nil,
    year: nil,
    is_author: false
  }

  # Simple fonction de passage qui traite un peu l'ISBN (pour le 
  # moment, on ne fait rien de sérieu, mais à l'avenir, si le label
  # reçoit un peu d'argent, on pourra s'abonner isbndb pour obtenir
  # les informations de n'importe quel livre)
  defp proceed_submit_book_with_isbn(procedure) do
    # IO.inspect(procedure.params, label: "Params dans submit_book_with_isbn")
    book_data = procedure.params["by_isbn"]
    isbn = book_data["isbn"]
    is_auteur = !is_nil(book_data["is_author"]) and book_data["is_author"] == "yes"

    book_data = Map.merge(@book_first_data, %{
      isbn: isbn, 
      is_author: is_auteur
    })
    # TODO Ne fonctionne pas encore
    # book_data = book_data_from_providers(book_data)

    procedure = Map.put(procedure, :book_data, book_data)
    # On passe directement à l'étape suivante
    proceed_submit_book_with_form(procedure)
  end

  # Fonction intermédiaire qui appelle le formulaire de soumission du
  # livre sans ISBN
  defp submit_book_with_form(procedure) do
    case check_captcha(procedure, "by_form") do
    :ok -> 
      params = procedure.params["by_form"]
      book_data = Map.merge(@book_first_data, %{
        is_author: !is_nil(params["is_author"]) and params["is_author"] == "yes"
      })
      proceed_submit_book_with_form(Map.merge(procedure, :book_data, book_data))
    {:error, message} -> message
    end
  end

  @doc """
  Étape de procédure qui affiche le formulaire pour soumettre les
  informations du livre et l'enregistrer pour le label.
  """
  def proceed_submit_book_with_form(procedure) do
    user = procedure.user
    book_data = procedure.book_data

    book_form = Html.Form.formate(%Html.Form{
      id: "submit-book-form",
      prefix: "book",
      captcha: true,
      fields: [
        %{type: :hidden, strict_name: "nstep", value: "consigner_le_livre"},
        %{type: :text, name: "title", label: "Titre du livre", required: true},
        %{type: :text, name: "author_firstname", label: "Prénom de l'autrice/auteur", required: true},
        %{type: :text, name: "author_lastname", label: "Nom de l'autrice/auteur", required: true},
        %{type: :text, name: "author_email", label: "Adresse de courriel de l'autrice/auteur"},
        %{type: :select, name: "author_sexe", label: "L'autrice/auteur est…", values: [["une femme", "F"], ["un homme", "H"]]},
        %{type: :checkbox, name: "is_author", value: "yes", label: "Je suis l'aut#{fem(:rice, user)} du livre", checked: book_data.is_author},
        %{type: :text, name: "isbn", label: "ISBN du livre", value: book_data.isbn, required: true},
        %{type: :date, name: "published_at", label: "Date de publication", value: Date.utc_today() |> Date.to_iso8601(), required: true},
        %{type: :text, name: "pitch", label: "Pitch (résumé court)", required: true},
        %{type: :select, name: "publisher", label: "Éditeur (maison d'éditions)", values: Lib.publishers_for_select()},
        %{type: :text, name: "new_publisher", label: "Autre éditeur", required: false},
        %{type: :select, name: "new_publisher_pays", label: "Pays du nouvel éditeur", values: Constantes.get(:pays_pour_menu)}
      ],
      buttons: [
        %{type: :submit, name: "Soumettre ce livre"}
      ]
    })

    """
    <h2>Caractéristiques du livre</h2>
    #{book_form}
    """
  end

  def consigner_le_livre(procedure) do
    user = procedure.user
    book_data = procedure.params["book"]
    is_author = !is_nil(book_data["is_author"]) and book_data["is_author"] == "yes"
    book_data = Map.merge(book_data, %{
      "is_author" => is_author
    })
    
    case book_registrable?(procedure, book_data) do
    :ok -> 
      proceed_consigner_le_livre(procedure, book_data)
      """
      <h2>Enregistrement du livre réussi !</h2>
      <p>Merci pour la soumission du livre #{inspect book_data["title"]}. 
      Dès qu'il aura été validé par l'administration du label et le comité
      de lecture, il pourra entrer en phase d'évaluation. Vous serez alors 
      informé#{fem(:e, user)} de toutes les étapes.</p>
      """
      
    erreur ->
      """
      <h2>Livre refusé</h2>
      <p>Malheureusement, ce livre ne peut pas être enregistré :</p>
      <p>#{erreur}</p>
      """
    end
  end

  def proceed_consigner_le_livre(procedure, book_data) do
    user = procedure.user
    is_author = book_data["is_author"]

    # - Création du livre et de l'auteur -
    {book, author} = create_book_and_author(Map.put(book_data, "user_id", user.id))

    # Actualisation de la procédure pour qu'elle connaisse le
    # livre et l'auteur pour les étapes suivantes
    data = Map.merge(procedure.data, %{
      book_id: book.id,
      author_id: author.id,
    })
    procedure = update_procedure(procedure, %{
      data: data,
      next_step: "auteur_confirme_soumission_livre"
      })

    IO.inspect(procedure, label: "\nPROCÉDURE FINALE de l'étape proceed_consigner_le_livre")

    # Les données propres aux mails
    mail_data = %{
      mail_id: "user-confirmation-submission-book",
      user: user,
      variables: %{
        book_title: book.title,
        book_isbn:  book.isbn
      },
      folder: __DIR__,
      procedure: procedure
    }


    # Mail pour l'user soumettant le livre
    send_mail(to: user, from: :admin, with: mail_data)
    
    # Mail à l'auteur du livre (même si c'est le même)
    # Dans ce mail, on lui demande de confirmer la soumission et
    # de rejoindre pour ça une page qui va lui permettre
    mail_data = %{mail_data | mail_id: "author-on-submission-book"}
    send_mail(to: author, from: :admin, with: mail_data)
    
    # Mail pour l'administration du label
    mail_data = %{mail_data | mail_id: "admin-annonce-submission-book"}
    send_mail(to: :admin, from: user, with: mail_data)

    # Annonce d'activité
    log_activity(%{
      public: true,
      owner_type: "author",
      owner_id:   author.id,
      creator:    user,
      text: "Soumission du livre “#{book.title}” de #{author.name}"
    })

    ajout_quand_auteur =
      if is_author do
        """
        <p>Puisque vous êtes l'aut#{fem(:rice, user)} de ce livre, vous
        devriez avoir reçu un mail vous permettant de confirmer sa
        candidature pour le label et pour transmettre le manuscrit qui
        permettra au comité de le lire et l'évaluer.</p>
        <p>Nous vous souhaitons de tout cœur de recevoir le label.</p>
        """
      else "" end
    # Confirmation (ou non) de l'enregistrement
    """
    <h2>Enregistrement du livre</h2>
    <p>Un grand merci à vous pour la soumission de ce livre.</p>
    <p>Vous devriez avoir reçu un mail de confirmation.</p>
    #{ajout_quand_auteur}
    """
  end

  @doc """
  Après la soumission du livre, l'auteur doit la confirmer pour que 
  le livre soit vraiment inscrit au label.
  """
  def auteur_confirme_soumission_livre(procedure) do
    # Barrière administrateur ou auteur du livre (attention, le vrai
    # auteur du livre, pas celui qui l'a soumis, qui peut être quelqu'un
    # d'autre que l'auteur)
    book    = procedure.book
    author  = book.author
    user_is_author = book.author.user_id == procedure.current_user.id
    user_is_admin  = current_user_is_admin?(procedure)

    cond do

    user_is_author ->
      # C'est l'auteur qui vient confirmer. Noter qu'il faut que ça 
      # soit avant le test de l'administrateur, car un administrateur
      # peut tout à fait être l'auteur d'un livre soumis.
      proceed_confirmation_soumission(procedure)

    user_is_admin ->
      # C'est un administrateur qui visite, on lui explique simple-
      # ment qu'on attend la validation de la soumission par l'auteur
      # du livre soumis.
      variables = Map.merge(%{book_title: book.title, book_author: book.author.name},
        Helpers.Feminines.as_map(author, "ff")
      )
      load_phil_text(
        __DIR__, 
        "admin-quand-auteur-confirme-submit",
        variables
        )

    true ->
      # Visiteur mal venu
      impasse(procedure)
    end
  end

  # Sous-fonction permettant à l'auteur du livre de confirmer sa
  # soumission ou au contraire de l'infirmer.
  defp proceed_confirmation_soumission(procedure) do
    user = procedure.user
    book = procedure.book

    """
    <h3>Confirmation de la soumission du livre</h3>

    <p>Bonjour #{user.name}, en tant qu’aut#{fem(:rice, user)} du livre 
    #{book.title}, vous devez confirmer sa soumission pour le label #{ldq_label()}
    afin que le comité de lecture puisse l’évaluer.</p>

    <p class=warning>Formulaire pour confirmer</p>
    """
  end


  @doc """
  Méthode finale qui permet, le cas échéant, de détruire le livre, 
  quand quelque chose s'est mal passé ou que l'auteur n'a pas respec-
  té les règles du label
  """
  def complete_book_remove(_operation) do
    raise "Je dois apprendre à supprimer complètement le livre."
  end


  ##### / FIN DES MÉTHODES ÉTAPES ######



  # ========= MÉTHODES DE CRÉATION ============

  # Enregistrement des premières cartes du nouveau livre avec les
  # données +data+ (transmises par le formulaire, donc avec des
  # clés binary)
  defp create_book_and_author(data) do
    # IO.inspect(data, label: "\n\n Data in create_book_and_author")
    is_author = data["is_author"]

    data_author =
      ["email", "firstname", "lastname", "sexe"]
      |> Enum.reduce(%{}, fn prop, map ->
        Map.put(map, prop, data["author_#{prop}"])
      end)
    data_author =
      if is_author do
        Map.put(data_author, "user_id", data["user_id"])
      else data_author end
    author = Lib.create_author!(data_author)
    
    # La maison d'édition
    publisher = get_publisher_in_params(data)

    # Les données pour créer le nouveau livre 
    # (rappel : LdQ.Library.Book est un format propre au label
    #  et qui ne fonctionne pas du tout comme les autres structures
    #  elixir/phoenix)
    data = Map.merge(data, %{
      "isbn"          => {nil, data["isbn"]},
      "author_id"     => {nil, author.id},
      "published_at"  => {nil, data["published_at"]},
      "publisher_id"  => {nil, publisher.id},
      "label"         => {nil, "false"},
      "current_phase" => {nil, "0"},
      "submitted_at"  => {nil, now()}
    })
    book = Lib.Book.save(data)

    {book, author}
  end

  # ========= MÉTHODES DE TESTS =============

  # @return :ok si le livre est registrable ou  l'erreur rencontrée
  # dans le cas contraire.
  defp book_registrable?(_procedure, book_data) do
    cond do
    !book_is_uniq(book_data) ->
      "Le livre doit être unique, or nous connaissons déjà un livre possédans le titre #{book_data["title"]} ou l'ISBN #{book_data["isbn"]}."
    true ->
      :ok
    end
  end

  # @return True si le livre défini par les données (paramètres URL)
  # +data+ n'existe pas encore en base de données
  # Note : Il existe si le titre existe avec le même ISBN
  defp book_is_uniq(data) do
    0 == 
      from(b in Book)
      |> where([b], b.title == ^data["title"])
      |> where([b], b.isbn == ^data["isbn"])
      |> Repo.all()
      |> Enum.count()
  end

  # ========= MÉTHODES UTILITAIRES =============

  # Méthode qui permet de récupérer ou de créer l'éditeur en fonction
  # des données fournies par le formulaire de dépôt d'un nouveau 
  # livre. Dans ce formulaire, l'user peut choisir un éditeur existant
  # ou en créer un nouveau.
  defp get_publisher_in_params(data) do
    pub_id = data["publisher"]
    case pub_id do
      "" ->
        case Lib.get_publisher_by_name(data["new_publisher"]) do
          nil ->
            Lib.create_publisher!(%{name: data["new_publisher"], pays: data["new_publisher_pays"]})
          publisher -> 
            publisher
        end
      pub_id -> 
        Lib.get_publisher!(pub_id)
    end
  end

  # defp book_data_from_providers(book_data) do
  #   isbn = book_data.isbn
  #   @isbn_providers
  #   |> Enum.reduce(%{retours: [], livre_found: nil}, fn {_provider_name, provider_url, methode}, collector ->
  #     if is_nil(collector.livre_found) do
  #       url = String.replace(provider_url, "__ISBN__", isbn)
  #       res = System.cmd("curl", [url])
  #       IO.inspect(res, label: "\n\nRetour de #{url}")
  #       res = 
  #         if methode == :none do
  #           res
  #         else
  #           apply(__MODULE__, methode, [res])
  #         end
  #       Map.merge(collector, %{
  #         retours: collector.retours ++ [res],
  #         livre_found: nil # TODO LE METTRE SI ON A PU LE RÉCUPÉRER
  #       })
  #     else
  #       collector
  #     end
  #   end)
  #   |> IO.inspect(label: "Résultat des pour #{isbn}")

  #   # Trouver sur le net les données du livre à partir des retours
  #   # TODO
  #   book_data
  # end

  # Méthode qui reçoit la page du site isbnsearch (site qui n'a pas
  # d'API) et en tire les données du livre
  def parse_from_isbn_search(_code) do
    IO.puts "Il faut que j'apprendre à extraire les données du livre de la page"
    # IO.inspect(code, label: "Code d'après ISBN Search")
    "[EXTRAIRE DONNÉES BOOK DE LA PAGE]"
  end

  # Méthode qui reçoit la page du site La Chasse aux livres (
  # recherche de livre par ISBN) et la traite pour extraire les
  # données du livre quand il est soumis par ISBN
  def parse_from_chasse_aux_livres(_code) do
    IO.puts "Il faut apprendre à extraire les données de la chasse aux livres"
    # IO.inspect(code, label: "Code d'après Chasse aux livres")
    "[EXTRAIRE LES DONNÉES DE LA CHASSE AUX LIVRES]"
  end
end