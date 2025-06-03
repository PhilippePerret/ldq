defmodule LdQ.Procedure.PropositionLivre do
  @moduledoc """
  Cette procédure commence avec la proposition d'un livre pour le
  label Lecture de Qualité et se termine par son attribution ou non
  du label suivi de son évaluation au fil du temps par les lecteurs.

  Il s'agit donc de la vie totale d'un livre au sein du label.

  TODO
  * bien penser à suivre les phases de l'évaluation (le paramètre current_phase)
    -> dans les tests aussi
    + penser à les tester pour ne pas pouvoir revenir à une étape finie

  """
  use LdQWeb.Procedure
  
  import LdQ.Site.PageHelpers # notamment pour ldq_label

  alias LdQ.Library, as: Lib
  alias LdQ.Library.Book
  alias LdQ.Comptes
  alias LdQ.Comptes.User

  def proc_name, do: "Évaluation d’un livre"

  @steps [
    %{name: "Soumission du livre", fun: :proposition_livre, admin_required: false, owner_required: false},
    %{name: "Soumission du livre par l'ISBN", no_name: true, fun: :submit_book_with_isbn, admin_required: false, owner_required: true},
    %{name: "Soumission du livre par formulaire", fun: :submit_book_with_form, admin_required: false, owner_required: true},
    %{name: "Consignation du livre", fun: :consigner_le_livre, admin_required: false, owner_required: true},
    %{name: "Confirmation de la soumission", fun: :form_confirmation_soumission_per_auteur, required: :user_is_author_or_admin?, admin_required: false, owner_required: false},
    %{name: "Soumission confirmée", fun: :author_confirm_submission, required: :user_is_author_or_admin?, admin_required: false, owner_required: false},
    %{name: "Choix du parrain", fun: :attribution_parrain, required: :user_is_author_or_admin?, admin_required: false, owner_required: false},
    %{name: "Attribution du parrain", fun: :proceed_attribute_parrain, required: :user_is_author_or_admin?, admin_required: false, owner_required: false},
    %{name: "Lancement de l'évaluation", fun: :start_evaluation, required: :user_is_author_or_admin?, admin_required: false, owner_required: false},
  
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
    {:error, message} -> {:error, message}
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
  def submit_book_with_form(procedure) do
    case check_captcha(procedure, "by_form") do
    :ok -> 
      params = procedure.params["by_form"]
      book_data = Map.merge(@book_first_data, %{
        is_author: !is_nil(params["is_author"]) and params["is_author"] == "yes"
      })
      proceed_submit_book_with_form(Map.merge(procedure, :book_data, book_data))
    {:error, message} -> {:error, message}
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
    <h4>Caractéristiques du livre</h4>
    #{book_form}
    """
  end

  @doc """
  Préconsignation du livre pour évaluation.
  """
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
      <p>Merci pour la soumission du livre #{inspect book_data["title"]}. 
      Dès qu'il aura été validé par l'administration du label et le comité
      de lecture, il pourra entrer en phase d'évaluation. Vous serez alors 
      informé#{fem(:e, user)} de toutes les étapes.</p>
      """
      
    erreur ->
      {:error,
        """
        <h2>Livre refusé</h2>
        <p>Malheureusement, ce livre ne peut pas être enregistré :</p>
        <p>#{erreur}</p>
        """
      }
    end
  end

  @doc """
  Fonction qui procède vraiment à l'enregistrement du livre pour
  évaluation.
  """
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
      next_step: "form_confirmation_soumission_per_auteur"
    })

    # IO.inspect(procedure, label: "\nPROCÉDURE FINALE de l'étape proceed_consigner_le_livre")

    # Placement d'un trigger qui doit se déclencher quelques mois
    # plus tard pour vérifier si le livre a bien été évalué
    # (note : d'autres triggers seront insérés aussi dans des sous-
    #  étapes)
    add_trigger("evaluation-book", %{book_id: book.id, procedure_id: procedure.id}, user.id)

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
    <p>Un grand merci à vous pour la soumission de ce livre.</p>
    <p>Vous devriez avoir reçu un mail de confirmation.</p>
    #{ajout_quand_auteur}
    """
  end

  def user_is_author_or_admin?(procedure) do
    book    = procedure.book
    user_is_author = book.author.user_id == procedure.current_user.id
    user_is_admin  = current_user_is_admin?(procedure)
    user_is_author || user_is_admin
  end

  @doc """
  Après la soumission du livre, l'auteur doit la confirmer pour que 
  le livre soit vraiment inscrit au label.
  (mais un administrateur devra encore confirmer que le livre est bon
   c'est-à-dire que toutes ses données sont définies)
  """
  def form_confirmation_soumission_per_auteur(procedure) do
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
      {:error, impasse(procedure)}
    end
  end

  # Sous-fonction permettant à l'auteur du livre de confirmer sa
  # soumission ou au contraire de l'infirmer.
  defp proceed_confirmation_soumission(procedure) do
    user = procedure.user
    book = procedure.book

    fields = [
      %{type: :hidden, strict_name: "nstep", value: "author_confirm_submission"},
      %{type: :text, name: "subtitle", label: "Sous-titre optionnel"},
      %{type: :textarea, name: "pitch", label: "Pitch (résumé court)", required: true},
      %{type: :text, name: "preversion_id", label: "Pré-version optionnelle", explication: "Si une version précédente du livre a été soumise au label, en l'ayant reçu ou non, indiquer ici son identifiant."},
      %{type: :date, name: "published_at", label: "Date de publication"},
      %{type: :text, name: "url_command", label: "URL de commande", required: true, explication: "Permet de certifier que l'ouvrage est bien mis en vente. Une fois le label reçu, cet URL permettra aux lectrice et aux lecteurs intéressés d'acheter le livre."},
      %{type: :checkbox, name: "accord_regles", value: "yes", strict_id: "accord_regles", label: "Je suis d’accord avec les <a href=\"/pg/regles-evaluation\">règles d'évaluation du label</a> et m'engage à les respecter"}
    ]

    # Quand on revient ici suite à une erreur de formulaire
    form_errors = Map.get(procedure, :form_errors, nil)

    # Quand c'est une re-présentation du formulaire, et que le 
    # manuscrit/livre a été envoyé, on ne demande plus de le redonner
    # on indique simplement son nom.
    fields = fields ++ (
      if is_nil(form_errors) || form_errors["book_file"] do
        # Première visite ou erreur sur le fichier
        [
          %{type: :file, name: "book_file", strict_id: "book_file", label: "Manuscrit/livre", explication: "Le manuscrit du livre pour être soumis sous n'importe quelle forme lisible, que ce soit un ePub, un fichier PDF, Word. Il convient simplement de s'assurer qu'il n'est pas protégé en lecture. S'il est trop lourd pour le formulaire, cocher la case ci-dessus et <a href=\"mailto:#{Constantes.get(:mail_admin)}\">transmettez-le par mail</a> (ou upload de gros fichiers)."},
          %{type: :checkbox, name: "send_by_mail", value: "yes", label: "Mon livre est gros, je préfère l'envoyer par mail"}
        ]
      else 
        [%{type: :raw, label: "Manuscrit/livre", content: "<div><em>Transmis avec succès</em></div>"}] 
      end
    )

    # # Juste pour vérifier si le fichier existe dans uploads
    # man_path = Map.get(procedure.data, "manuscrit_path", nil)
    # if is_nil(man_path) do
    #   IO.puts "Pas de manuscrit/livre défini dans procedure.data"
    # else
    #   IO.puts "Path du manuscrit : #{man_path}"
    #   IO.puts "Existe : #{File.exists?(man_path)}"
    # end

    form = Html.Form.formate(%Html.Form{
      id: "confirm-submit-book",
      prefix: "book",
      captcha: true,
      errors: form_errors,
      values: Map.get(procedure, :params, %{}),
      fields: fields,
      buttons: [
        %{type: :submit, name: "Soumettre mon livre"}
      ]
    })

    """
    <p>Bonjour #{user.name}, en tant qu’aut#{fem(:rice, user)} du livre 
    #{book.title}, vous devez confirmer sa soumission pour le label #{ldq_label()}
    afin que le comité de lecture puisse l’évaluer. Cette confirmation consiste à 
    remplir le formulaire ci-dessous.</p>

    #{form}
    """
  end

  @doc """
  Fonction appelée quand l'auteur confirme la soumission de son livre.
  Mais celle-ci ne fait que vérifier le captcha, c'est la suivante
  qui procède véritablement à l'opération.
  """
  def author_confirm_submission(procedure) do
    case check_captcha(procedure, "book") do
    :ok -> check_author_confirm_submission(procedure)
    {:error, message} -> {:error, message}
    end
  end

  defp check_author_confirm_submission(procedure) do
    _book = procedure.book
    params = procedure.params["book"]
    # IO.inspect(params, label: "BOOK PARAMS")
    # --- Vérifications ---
    resultat = 
    %{ok: true, errors: %{}, procedure: procedure}
    |> livre_ou_manuscrit_transmit(params)
    |> signature_accord_regles(params)
    |> url_commande_valide(params)

    # La procédure a pu être modifiée
    procedure = resultat.procedure
    # |> IO.inspect(label: "PROCÉDURE MODIFIÉE")

    if resultat.ok do
      # On poursuit avec l'enregistrement du livre soumis
      try do
        proceed_author_confirm_submission(procedure)
      rescue
        e in LdQ.Error -> LdQ.Error.message(e, %{admin: User.admin?(procedure.current_user)})
      end
    else
      # On ressoumet le formulaire
      rerun_procedure(Map.put(procedure, :form_errors, resultat.errors), :form_confirmation_soumission_per_auteur)
    end
  end

  # Note : On ne passe ici que lorsque tout est OK et certifié
  defp proceed_author_confirm_submission(procedure) do
    book = procedure.book

    mails_variables = %{
      book_title: book.title,
      author_name: book.author.name,
      proc_url: proc_url(procedure),
      app_url: Constantes.get(:app_url), # pour les url
      proc_url_author: proc_url(procedure, [title: "cette page réservée à votre livre"])

    }
    |> Map.merge(Helpers.Feminines.as_map(book.author.sexe, "auth")) # => auth_<...>)

    # Enregistrer les nouvelles données du livre
    # --- Enregistrement des nouvelles informations pour le livre ---
    params = Map.merge(procedure.params["book"], %{
      "transmitted"   => File.exists?(procedure.data["manuscrit_path"]),
      "last_phase"    => 15,
      "current_phase" => 18,
      "submitted_at"  => now()
    })
    # IO.inspect(params, label: "NEW PARAMS BOOK")

    book = 
      case Book.save(book, params) do
        %Book{} = updated_book -> updated_book
        erreur -> raise(LdQ.Error, code: :error_save, msg: "Impossible d'enregistrer le livre : #{erreur}", data: params)
      end
    # IO.inspect(book, label: "\nLIVRE ACTUALISÉ")

    # Mettre l'étape suivante dans la procédure
    # (il s'agit de l'étape ou un administrateur va désigner un
    #  parrain et mettre le livre en évaluation)
    proc_attrs = %{
      next_step: "attribution_parrain"
    }
    # Actualisation de la procédure
    procedure = update_procedure(procedure, proc_attrs)

    # Informer l'administration
    send_mail(to: :admin, from: :admin, with: %{
      mail_id: "to_admin-author-autorise-evaluation",
      procedure: procedure, 
      folder: __DIR__,
      variables: mails_variables
    })

    # Lettre de confirmation à l'auteur
    send_mail(to: book.author, from: :admin, with: %{
      mail_id: "to_author-confirme-son-autorisation",
      procedure: procedure,
      folder: __DIR__,
      variables: mails_variables
    })

    # Nouvelle actualité
    log_activity(%{
      public: true,
      owner_type: "author",
      owner_id: book.author.id,
      creator: procedure.current_user,
      text: "<p>Mise en évaluation du livre <em>#{book.title}</em> de #{book.author.name}</p>"
    })

    # Pour le mmoment, les mêmes que pour les mails
    data_template = mails_variables
    # |> Map.merge(%{})



    load_phil_text(__DIR__, "auteur-quand-auteur-confirme-submit", data_template)
  end


  @doc """
  Après autorisation complète de l'évaluation par l'auteur, un 
  administrateur va choisir un parrain pour le livre et mettre ce 
  livre en évaluation.

  Note : seul un administrateur peut passer par ici.
  """
  def attribution_parrain(procedure) do
    curuser = procedure.current_user
    if User.admin?(curuser) do
      form_attribution_parrain(procedure)
    else
      # Forcément l'auteur du livre
      "<p>Bonjour ch#{fem(:ere, curuser)} #{curuser.name}, comme vous pouvez le deviner par le titre, l'administration est en train de chercher un parrain pour votre livre, c'est-à-dire un membre du comité de lecture qui l'accompagnera pendant tout son processus d'évaluation.</p>"
    end
  end

  # Pour permettre à l'administrateur de choisir un parrain
  defp form_attribution_parrain(procedure) do
    membres = Comptes.get_users(membre: true, sort: :credit, book_count: true)
    options_parrains = Enum.map(membres, fn membre ->
      [membre.name, membre.id]
    end)
    detail_membres = build_detail_membres(membres)
    # TODO Rappeler qu'un parrainage rapporte des points, quel que soit le livre
    form = Html.Form.formate(%Html.Form{
      id: "choose-book-parrain",
      action: "/proc/#{procedure.id}",
      prefix: "book",
      captcha: false,
      fields: [
        %{type: :hidden, strict_name: "nstep", value: "proceed_attribute_parrain"},
        %{type: :select, name: "parrain_id", options: options_parrains, label: "Parrain choisi"}
      ],
      buttons: [
        %{type: :submit, name: "Attribuer ce parrain"}
      ]
    })
    """
    <p>Merci de choisir un parrain.</p>
    #{form}
    #{detail_membres}
    """
  end

  @doc """
  Fonction qui procède à la définition du parrain du livre. On l'alerte
  et on lui donne des points en plus.
  """
  def proceed_attribute_parrain(procedure) do
    book = procedure.book

    parrain_id = procedure.params["book"]["parrain_id"]
    parrain = Comptes.get_user!(parrain_id)
    
    # On renseigne le parrain et la phase du livre
    Book.save(book, %{parrain_id: parrain_id, last_phase: "15", current_phase: "18"})

    # Ajout des points de crédit au parrain
    points_parrain =  LdQ.Evaluation.CreditCalculator.points_for(:parrainage)
    old_points_parrain = (parrain.credit || 0)
    new_points_parrain = old_points_parrain + points_parrain
    User.update_credit(parrain, new_points_parrain)

    variables_mail = Map.merge(%{
      mb_name:          parrain.name,
      membre_credit:    "#{new_points_parrain}",
      points_credit:    "#{points_parrain}",
      points_penalite:  "#{-LdQ.Evaluation.CreditCalculator.points_for(:refus_parrainage)}",
      author_name:      book.author.name,
      book_title:       book.title
    }, Helpers.Feminines.as_map(parrain.sexe, "mb"))

    send_mail(to: parrain, from: :admin, with: %{
      procedure: procedure,
      folder: __DIR__, 
      mail_id: "to_membre-demande-parrainage", 
      variables: variables_mail
    })
    
    start_evaluation_form = Html.Form.formate(%Html.Form{
      id: "start-evaluation",
      action: "/proc/#{procedure.id}",
      captcha: false,
      fields: [
        %{type: :hidden, strict_name: "nstep", value: "start_evaluation"}
      ],
      buttons: [
        %{type: :submit, name: "Lancer l'évaluation du livre"}
      ]
    })
    
    """
    <p>Le parrainnage du livre #{book.title} (#{book.author.name}) a bien été 
    attribué à #{parrain.name}. Son crédit est passé de #{old_points_parrain} à 
    #{new_points_parrain}.</p>
    <p>Il a tout loisir de refuser ce parrainage bien entendu.</p>
    <p>Vous pouvez à présent :</p>
    #{start_evaluation_form}
    """
  end

  def start_evaluation(procedure) do
    curuser = procedure.current_user
    if User.admin?(curuser) do
      # Forcément un administrateur
      proceed_start_evaluation(procedure)
    else
      # Forcément l'auteur du livre
      "<p>Bonjour ch#{fem(:ere, curuser)} #{curuser.name}, comme vous pouvez le deviner par le titre, l'administration doit lancer l'évaluation de votre livre.</p>"
    end
  end

  # Fonction qui procède à la mise en évaluation du livre. C'est le 
  # déclenchement effectif de son évaluation.
  defp proceed_start_evaluation(procedure) do
    book  = procedure.book
    admin = procedure.current_user
    User.admin?(admin) || raise("On essaie de forcer cette fonction…")

    mail_variables = Map.merge(%{
      book_title: book.title,
      author_name: book.author.name,
      url_procedure: proc_url(procedure, title: "Suivre la procédure d'évaluation")
    }, Helpers.Feminines.as_map(book.author.sexe, "auth"))

    # Le livre est marqué pour passer à l'évaluation
    Book.save(book, %{last_phase: "18", current_phase: "20"})

    # Un trigger est lancé, pour s'assure que le quorum du premier 
    # collège sera atteint dans les temps
    add_trigger("deadline-quorum-college-1", %{book_id: book.id, procedure_id: procedure.id}, admin.id)

    # Mail d'information à l'auteur
    send_mail(to: book.author, from: :admin, with: %{
      procedure: procedure,
      folder: __DIR__,
      mail_id: "to_author-lancement-evaluation", 
      variables: mail_variables
    })

    # Les lecteurs du niveau correspondant sont informés
    # Note : ça se fait par Brevo
    send_mailing(:college1, "new-book-to-evaluate", [
      procedure: procedure,
      folder:   __DIR__,
      variable: mail_variables
    ])

    # Une annonce d'activité est enregistrée
    log_activity(%{
      public: true,
      owner_type: "author",
      owner_id:   book.author.id,
      creator:    admin,
      text: "Mise en évaluation du livre “#{book.title}” de #{book.author.name}"
    })

    """
    <p class=success>La livre #{book.title} de #{book.author.name} a été mis en évaluation.</p>
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


  # ======== FONCTIONS DE CHECK DE L'AUTORISATION PAR L'AUTEUR =============

  defp livre_ou_manuscrit_transmit(res, params) do
    procedure = res.procedure
    if res.ok do
      if params["book_file"] do
        # C'est la première soumission du formulaire
        %Plug.Upload{filename: filename, path: tmp_path} = params["book_file"]
        books_folder = ensure_books_folder()
        dest_path = Path.join([books_folder, "book-#{procedure.id}#{Path.extname(filename)}"])
        File.cp!(tmp_path, dest_path)
        newproc = update_data_procedure(procedure, %{manuscrit_path: dest_path})
        %{res | procedure: newproc}
      else
        # C'est une autre soumission où le manuscrit a été transmit.
        # On doit le trouver dans le dossier des livres
        man_path = procedure.data["manuscrit_path"]
        if File.exists?(man_path) do
          res
        else
          Html.Form.add_error(res, "book_file", "Le fichier consigné est introuvable… Il faut le redonner.")
        end
      end
    else res end
  end

  defp signature_accord_regles(res, params) do
    if res.ok do
      if params["accord_regles"] == "yes" do 
        res 
      else
        Html.Form.add_error(res, "accord_regles", "Il faut approuver les règles du label")
      end
    else res end
  end
  defp url_commande_valide(res, params) do
    if res.ok do
      url = params["url_command"]
      case Book.validate("url_command", nil, url, nil) do
      :ok -> res
      {:error, _erreur} -> Html.Form.add_error(res, "accord_regles", "Il faut entrer une URL valide et qui permet d'acheter le livre.")
      end
    else res end
  end
  
  # Construit un listing des membres du comité de lecture en respec-
  # tant les options +options+
  # 
  # @param {Keyword} options
  #   :sort   Clé de classement
  #
  # @return {HTMLString} Listing au format HTML
  defp build_detail_membres(membres, options \\ []) do
    # On relève tous les users qui sont membres du comité de lecture
    """
    <style type="text/css">
      table#member-list {
      }
      table#member-list tr td:nth-child(1) {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis
      }
      table#member-list tbody > tr:nth-of-type(even) {
        background-color: rgb(237 238 242);
      }
    </style>
    <table id="member-list" cellspacing="4">
      <thead>
        <tr>
          <th width="300">Membre du comité</th>
          <th width="auto">Email</th>
          <th width="100">Nombre<br/>livres</th>
          <th width="120">Crédit</th>
        </tr>
      </thead>
      <tbody>
    """ <> (
      Enum.map(membres, fn u ->
        ~s(<tr><td>#{u.name}</td><td>#{Comptes.email_link_for(u, title: "Contacter")}</td><td class="center">#{u.book_count}</td><td class="center">#{u.credit}</td></tr>)
      end)
      |> Enum.join("")
    ) <> "</tbody></table>"
  end

end