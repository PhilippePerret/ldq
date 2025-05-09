defmodule LdQ.Procedure.PropositionLivre do
  @moduledoc """
  Cette procédure commence avec la proposition d'un livre pour le
  label Lecture de Qualité jusqu'à sa mise en test.
  Donc il ne s'agit que du début de la longue procédure.
  """
  use LdQWeb.Procedure

  alias LdQ.Library, as: Lib
  alias LdQ.Library.Book

  def proc_name, do: "Soumission d’un livre au label"

  @steps [
    %{name: "Proposition du livre", fun: :proposition_livre, admin_required: false, owner_required: false},
    %{name: "Soumission par l'ISBN", fun: :submit_book_with_isbn, admin_required: false, owner_required: true},
    %{name: "Soumission par formulaire", fun: :submit_book_with_form, admin_required: false, owner_required: true},
    %{name: "Consigner le livre pour évaluation", fun: :consigner_le_livre, admin_required: false, owner_required: true}
  ]
  def steps, do: @steps


  @doc """
  Fonction qui détermine (en fonction de la procédure) les données à
  enregistrer dans la table
  """
  def procedure_attributes(params) do
    user = params.user
    %{
      proc_dim:     "proposition-livre",
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
        %{type: :text, name: "isbn", label: "ISBN du livre"},
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

  @isbn_providers [
    {"ISBN Search", "https://isbnsearch.org/isbn/__ISBN__", :parse_from_isbn_search},
    {"google books", "https://www.googleapis.com/books/v1/volumes?q=isbn:__ISBN__", :none},
    {"open library", "https://openlibrary.org/api/books?bibkeys=ISBN:__ISBN__&format=json&jscmd=details", :none},
    {"word cat", "http://xisbn.worldcat.org/webservices/xid/isbn/__ISBN__?method=getMetadata&fl=*&format=json", :none},
    {"Chasse aux livres", "https://www.chasse-aux-livres.fr/recherche-par-isbn/search?catalog=fr&query=__ISBN__", :parse_from_chasse_aux_livres}
    # Le meilleur mais Par abonnement {"ISBN Db", "https://api2.isbndb.com/book/__ISBN__"}
  ]

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

  def proceed_submit_book_with_isbn(procedure) do
    # IO.inspect(procedure.params, label: "Params dans submit_book_with_isbn")
    book_data = procedure.params["by_isbn"]
    isbn = book_data["isbn"]
    is_auteur = !is_nil(book_data["is_author"]) and book_data["is_author"] == "yes"

    book_data = %{
      isbn: isbn, is_author: is_auteur
    }
    # TODO Ne fonctionne pas encore
    # book_data = book_data_from_providers(book_data)

    procedure = Map.put(procedure, :book, book_data)
    # On passe directement à l'étape suivante
    proceed_submit_book_with_form(procedure)
  end

  def submit_book_with_form(procedure) do
    case check_captcha(procedure, "by_form") do
    :ok -> proceed_submit_book_with_form(procedure)
    {:error, message} -> message
    end
  end

  def proceed_submit_book_with_form(procedure) do
    user = procedure.user
    book = if Map.has_key?(procedure, :book) do
      # Quand l'user a demandé la soumission par ISBN et que les
      # information du livre ont pu être récupérées
      procedure.book
    else %{
      title: nil, 
      pitch: nil, 
      author_firstname: nil,
      author_lastname: nil,
      author_email: nil,
      isbn: nil,
      publisher: nil,
      year: nil
    }
    end

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
        %{type: :checkbox, name: "is_author", value: "yes", label: "Je suis l'aut#{fem(:rice, user)} du livre", checked: book.is_author},
        %{type: :text, name: "isbn", label: "ISBN du livre", value: book.isbn, required: true},
        %{type: :text, name: "year", label: "Année de publication", required: true},
        %{type: :text, name: "pitch", label: "Pitch (résumé court)", required: true},
        %{type: :text, name: "publisher", label: "Éditeur (Maison d'éditions)", required: false}
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
    {:error, erreur} ->
      """
      <h2>Livre refusé</h2>
      <p>Malheureusement, ce livre ne peut pas être enregistré :</p>
      <p>#{raison}</p>
      """
    end
  end

  def proceed_consigner_le_livre(procedure, book_data) do
    user = procedure.user
    is_author = book_data["is_author"]
    {book, author} = book_cards_saved(book_data)
    # Actualisation de la procédure pour qu'elle connaisse le
    # livre et l'auteur
    data = Map.merge(procedure.data, %{
      book_id: book.id,
      author_id: author.id,
    })
    update_procedure(procedure)

    # Les données propres aux mails
    mail_data = %{
      book_title: book.title,
      book_isbn:  book.isbn
    }

    # Mail pour l'user soumettant le livre
    send_mail(to: user, from: :admin, with: %{id: "user-confirmation-submission-book", variables: mail_data})

    # Mail pour l'administration du label
    # TODO

    # Mail à l'auteur du livre (même si c'est le même)
    # Dans ce mail, on lui demande de confirmer la soumission et
    # de rejoindre pour ça une page qui va lui permettre
    # TODO

    # Annonce d'activité
    # TODO (contenant "soumission d’un nouveau livre")

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
    <p class="warning">Je dois apprendre à consigner le livre</p>
    """
  end

  # ========= MÉTHODES DE CRÉATION ============

  # Enregistrement des premières cartes du nouveau livre avec les
  # données +data+
  defp book_cards_saved(data) do
    data_author =
      [:email, :firstname, :lastname]
      |> Enum.reduce(%{}, fn prop, map ->
        Map.put(map, prop, data["author_#{prop}"])
      end)
    author =
      Lib.Author.changeset(%Lib.Author{}, data_author)
      |> Repo.insert!()
    
    data = Map.put(data, "author_id", author.id)

    book =
      Book.MiniCard.changeset(%Book.MiniCard{}, data)
      |> Repo.insert()
    
    {book, author}
  end

  # ========= MÉTHODES DE TESTS =============

  # @return :ok si le livre est registrable ou {:error, <erreur>} 
  # dans le cas contraire.
  defp book_registrable?(procedure, book_data) do
    cond do
    !book_is_uniq(book_data) ->
      "Le livre doit être unique, or nous connaissons déjà un livre possédans le titre #{book_data["title"]} ou l'ISBN #{book_data["isbn"]}."
    true ->
      :ok
    end
  end

  # @return True si le livre défini par les données (paramètres URL)
  # +data+ n'existe pas encore en base de données
  defp book_is_uniq(data) do
    query = from(b in Book.MiniCard)
    query = query
      |> join(:inner, [b], sp in Book.Specs, on: sp.book_minicard_id == b.id)
      |> join(:inner, [b], ev in Book.Evaluation, on: ev.book_minicard_id == b.id)

    query = query
      |> where(title: ^data["title"])
      |> where([b, sp], sp.isbn == ^data["isbn"])

    found = Repo.all(query)
    Enum.count(found) == 0
  end

  # ========= MÉTHODES UTILITAIRES =============

  defp book_data_from_providers(book_data) do
    isbn = book_data.isbn
    @isbn_providers
    |> Enum.reduce(%{retours: [], livre_found: nil}, fn {provider_name, provider_url, methode}, collector ->
      if is_nil(collector.livre_found) do
        url = String.replace(provider_url, "__ISBN__", isbn)
        res = System.cmd("curl", [url])
        IO.inspect(res, label: "\n\nRetour de #{url}")
        res = 
          if methode == :none do
            res
          else
            apply(__MODULE__, methode, [res])
          end
        Map.merge(collector, %{
          retours: collector.retours ++ [res],
          livre_found: nil # TODO LE METTRE SI ON A PU LE RÉCUPÉRER
        })
      else
        collector
      end
    end)
    |> IO.inspect(label: "Résultat des pour #{isbn}")

    # Trouver sur le net les données du livre à partir des retours
    # TODO
    book_data
  end

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