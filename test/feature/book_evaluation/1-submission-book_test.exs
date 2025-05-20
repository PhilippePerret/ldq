defmodule LdQWeb.BookSubmissionTestsStep1 do
  @moduledoc """
  Module de test permettant de tester l'évaluation d'un livre, depuis
  sa soumission jusqu'à l'attribution de son label (ou pas).
  Ce module unique permet de tester les choses quand tout va bien et
  que le livre passe toutes les étapes.
  On se sert intenséement de bdd_dump et bdd_load pour repartir d'un
  point précis de la base.

  QUESTION :

  Comment s'assurer de la validité du livre => par l'ISBN ? en faisant une
  recherche sur Amazon (sur un autre site)
  REPONSE : Pour le moment, il n'y a pas de moyen gratuit de s'assurer de
  l'existence du livre par ISBN.

  """
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  @tag :admin
  @tag :user
  @tag :author
  test "Un utilisateur identifié peut soumettre un nouveau livre" do
    # on_exit(fn -> bdd_dump("book-just-submitted") end)

    detruire_les_mails()

    user = make_user_with_session(%{name: "Autrice DuLivre", password: "passepartout"})

    book_data = %{
      title: "Mon plus beau livre du #{now()}",
      isbn: "9782487613027", # Analyse Au clair de Lune
      author_firstname: "Autrice",
      author_lastname: "DuLivre",
      author_sexe: "F",
      author_email: user.email,
      published_at: Date.add(Date.utc_today(), -60),
      pitch: "Analyse autopsique d'un assassinat de Juillet",
      publisher: "",
      new_publisher: "Oxford Editions",
      new_publisher_pays: "en"
    }

    user
    |> rejoint_la_page("/")
    |> clique_le_lien("soumettre votre livre")
    # Il doit se connecter
    |> se_connecte()
    |> pause(1)
    |> et_voit("h3", "Soumission du livre")
    |> pause(1)
    # Il trouve un formulaire pour choisir entre définir le livre par son ISBN
    # ou par formulaire
    |> et_voit(["Soumettre par formulaire", "Soumettre par ISBN"])
    # |> remplit_le_champ("ISBN") |> avec("9798883337573") # Livre gabarits
    |> remplit_le_champ("ISBN") |> avec(book_data.isbn) 
    |> coche_la_case("#by_isbn_is_author")
    |> choisit_le_bon_captcha(%{form_id: "form-submit-with-isbn", prefix: "by_isbn"})
    |> pause(1)
    |> clique_le_bouton("Soumettre par ISBN")
    |> pause(1)
    # Ici, le programme recherche le livre par son isbn

    point_test = now()

    user
    |> pause(1)
    |> et_voit("h4", "Caractéristiques du livre")
    |> pause(1)
    |> remplit_le_champ("Titre du livre") |> avec(book_data.title)
    |> remplit_le_champ("Prénom de l'autrice/auteur") |> avec(book_data.author_firstname)
    |> remplit_le_champ("Nom de l'autrice/auteur") |> avec(book_data.author_lastname)
    |> choisit_le_menu("L'autrice/auteur est…", book_data.author_sexe)
    |> remplit_le_champ("Adresse de courriel de l'autrice/auteur") |> avec(book_data.author_email)
    |> remplit_le_champ("Date de publication") |> avec(book_data.published_at)
    |> remplit_le_champ("Pitch (résumé court)") |> avec(book_data.pitch)
    |> choisit_le_menu("Éditeur (maison d'éditions)", book_data.publisher)
    |> remplit_le_champ("Autre éditeur") |> avec(book_data.new_publisher)
    |> choisit_le_menu("Pays du nouvel éditeur", book_data.new_publisher_pays)
    |> choisit_le_bon_captcha(%{form_id: "submit-book-form", prefix: "book"})
    |> clique_le_bouton("Soumettre ce livre")
    |> pause(1)
    # On doit se trouver sur la page de registration
    |> et_voit("h3", "Consignation du livre")

    # --- Vérification ---

    # S'assurer que les cartes du livres ont bien été créées
    # (le full: true ci-dessous signifie qu'on checke aussi ses cartes)
    new_book = assert_book_exists(full: true, after: point_test, author_email: user.email)

    # S'assurer que l'auteur a été créé
    assert_author_exists(after: point_test, email: new_book.author.email, firstname: new_book.author.firstname)

    user
    # En tant que soumetteuse du livre
    |> recoit_un_mail(after: point_test, mail_id: "user-confirmation-submission-book")
    # en tant qu'autrice du livre
    |> recoit_un_mail(after: point_test, mail_id: "author-on-submission-book")
    |> has_activity(after: point_test, as: :creator, content: "Soumission du livre “#{book_data.title}”")

    admin = make_admin_with_session()

    admin
    |> recoit_un_mail(after: point_test, mail_id: "admin-annonce-submission-book")

    # La prochaine étape doit être la bonne
    procedure = last_procedure_of(user, "evaluation-livre")
    assert procedure.next_step == "auteur_confirme_soumission_livre"

    # La procédure a bien mémorisé l'identifiant du livre et de 
    # l'autueur
    data_proc = procedure.data
    assert Map.has_key?(data_proc, "author_id")
    assert Map.has_key?(data_proc, "book_id")
    assert(data_proc["book_id"] == new_book.id)
    assert(data_proc["author_id"] == new_book.author.id)

    # Photographie de la BDD après enregistrement de la soumission du livre
    bdd_dump("book-just-submitted", %{
      user: user,
      admin: admin,
      point_test: point_test,
      procedure_id: procedure.id
    })

  end

end