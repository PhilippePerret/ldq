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
    %{name: "Soumission par formulaire", fun: :submit_book_with_form, admin_required: false, owner_required: true}
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
        %{type: :checkbox, name: "is_author", label: "Je suis l'aut#{fem(:rice, user)} du livre"}
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
        %{type: :checkbox, name: "is_author", label: "Je suis l'aut#{fem(:rice, user)} du livre"}
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
    is_auteur = data_book["is_author"]

    @isbn_providers
    |> Enum.reduce(%{retours: [], livre_found: nil}, fn {provider_name, provider_url, methode}, collector ->
      if is_nil(collector.livre_found) do
        url = String.replace(provider_url, "__ISBN__", isbn)
        res = System.cmd("curl", [url])
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
    # Trouver sur le net les données du livre
    # TODO
    procedure = Map.put(procedure, :book, %{title: "À voir"})
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
    else %{} end

    """
    <h2>Caractéristiques du livre</h2>
    <p class=warning>Je dois mettre le formulaire de soumission ici</p>
    """
  end

  


  # ========= MÉTHODES UTILITAIRES =============

  # Méthode qui reçoit la page du site isbnsearch (site qui n'a pas
  # d'API) et en tire les données du livre
  def parse_from_isbn_search(code) do
    IO.puts "Il faut que j'apprendre à extraire les données du livre de la page"
    "[EXTRAIRE DONNÉES BOOK DE LA PAGE]"
  end

  # Méthode qui reçoit la page du site La Chasse aux livres (
  # recherche de livre par ISBN) et la traite pour extraire les
  # données du livre quand il est soumis par ISBN
  def parse_from_chasse_aux_livres(code) do
    IO.puts "Il faut apprendre à extraire les données de la chasse aux livres"
    "[EXTRAIRE LES DONNÉES DE LA CHASSE AUX LIVRES]"
  end
end