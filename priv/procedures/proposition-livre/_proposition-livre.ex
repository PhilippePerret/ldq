defmodule LdQ.Procedure.PropositionLivre do
  @moduledoc """
  Cette procédure commence avec la proposition d'un livre pour le
  label Lecture de Qualité jusqu'à sa mise en test.
  Donc il ne s'agit que du début de la longue procédure.
  """
  use LdQWeb.Procedure

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
    IO.inspect(procedure.params, label: "Params dans submit_book_with_isbn")
    data_book = procedure.params["by_isbn"]
    isbn = data_book["isbn"]
    is_auteur = !is_nil(data_book["is_author"]) and data_book["is_author"] == "yes"

    data_book = %{
      isbn: isbn, is_author: is_auteur
    }
    # TODO Ne fonctionne pas encore
    # data_book = book_data_from_providers(data_book)

    procedure = Map.put(procedure, :book, data_book)
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
    data_book = procedure.params["book"]
    is_author = !is_nil(data_book["is_author"]) and data_book["is_author"] == "yes"
    
    # Vérification de l'unicité du livre
    # TODO

    # Enregistrement des premières cartes du livres
    # TODO

    # Enregistrement des données du livre dans la procédure, 
    # notamment pour ne permettre qu'à l'auteur de passer par
    # la prochaine étape (soumission du manuscrit)
    # TODO


    # Mail pour l'user soumettant le livre
    # TODO

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

  


  # ========= MÉTHODES UTILITAIRES =============

  defp book_data_from_providers(data_book) do
    isbn = data_book.isbn
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
    data_book
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