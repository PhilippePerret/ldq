defmodule LdQWeb.BookSubmissionTests do
  @moduledoc """
  Module de test permettant de tester la soumission d'un livre en 
  mode intégration.

  QUESTION :

  Comment s'assurer de la validité du livre => par l'ISBN ? en faisant une
  recherche sur Amazon (sur un autre site)
  """
  use LdQWeb.FeatureCase, async: false

  # alias Helpers.Feminines, as: Fem

  import TestHelpers
  import FeaturePublicMethods

  # @tag :skip
  test "Un utilisateur quelconque peut soumettre un nouveau livre" do

    user = make_user_with_session(%{name: "Autrice DuLivre"})

    book_data = %{
      title: "Mon plus beau livre du #{now()}",
      isbn:  "9782487613027", # Analyse Au clair de Lune
      author_firstname: "Autrice",
      author_lastname: "DuLivre",
      author_email: user.email,
      year: "2023",
      pitch: "Analyse autopsique d'un assassinat de Juillet",
      publisher: ""
    }

    user
    |> rejoint_la_page("/")
    |> clique_le_lien("soumettre votre livre")
    # Il doit se connecter
    |> se_connecte()
    |> pause(1)
    |> et_voit("h2", "Soumission d’un livre")
    |> pause(1)
    # Il trouve un formulaire pour choisir entre définir le livre par son ISBN
    # ou par formulaire
    |> et_voit(["Soumettre par formulaire", "Soumettre par ISBN"])
    # |> remplit_le_champ("ISBN") |> avec("9798883337573") # Livre gabarits
    |> remplit_le_champ("ISBN") |> avec(book_data.isbn) 
    |> coche_la_case("#by_isbn_is_author")
    # https://openlibrary.org/isbn/9798883337573.json
    |> choisit_le_bon_captcha(%{form_id: "form-submit-with-isbn", prefix: "by_isbn"})
    |> pause(1)
    |> clique_le_bouton("Soumettre par ISBN")
    |> pause(1)
    # Ici, le programme recherche le livre par son isbn

    point_test = now()

    user
    |> pause(1)
    |> et_voit("h2", "Caractéristiques du livre")
    |> pause(1)
    |> remplit_le_champ("Titre du livre") |> avec(book_data.title)
    |> remplit_le_champ("Prénom de l'autrice/auteur") |> avec(book_data.author_firstname)
    |> remplit_le_champ("Nom de l'autrice/auteur") |> avec(book_data.author_lastname)
    |> remplit_le_champ("Adresse de courriel de l'autrice/auteur") |> avec(book_data.author_email)
    |> remplit_le_champ("Année de publication") |> avec(book_data.year)
    |> remplit_le_champ("Pitch (résumé court)") |> avec(book_data.pitch)
    |> remplit_le_champ("Éditeur (Maison d'éditions)") |> avec(book_data.publisher)
    |> choisit_le_bon_captcha(%{form_id: "submit-book-form", prefix: "book"})
    |> clique_le_bouton("Soumettre ce livre")
    |> pause(2)
    # On doit se trouver sur la page de registration
    |> et_voit("h2", "Enregistrement du livre")

    # --- Vérification ---

    # S'assurer que les cartes du livres ont bien été créées
    new_book = assert_book_exists(after: point_test, author_email: user.email)
    # TODO

    # S'assurer que l'auteur a été créé
    assert_author_exists(after: point_test, email: new_book.author.email, firstname: new_book.author.firstname)

    user
    # En tant que soumetteuse du livre
    |> recoit_un_mail(after: point_test, mail_id: "user-confirmation-submission-book")
    # en tant qu'autrice du livre
    |> recoit_un_mail(after: point_test, mail_id: "author-on-submission-book")
    |> has_activity(after: point_test, content: "soumission d’un nouveau livre")

    admin = make_admin_with_session()

    admin
    |> recoit_un_mail(after: point_test, mail_id: "admin-annonce-submission-book")


  end

  @tag :skip
  test "Un non inscrit ne peut pas soumettre un livre" do
  end

  @tag :skip
  test "On ne peut pas soumettre de force un formulaire incomplet" do
  end

  @tag :skip
  test "On peut soumettre un livre directement par formulaire" do
  end

  @tag :skip
  test "On ne peut pas soumettre deux fois le même livre" do
  end

  @tag :skip
  test "Soumission par quelqu'un d'autre que l'auteur" do
    # L'auteur reçoit un mail aussi
  end

end