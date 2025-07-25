defmodule LdQWeb.BookSubmissionTestsStep3_1 do
  use LdQWeb.FeatureCase, async: false

  import TestHelpers, except: [now: 0]
  import FeaturePublicMethods

  # @tag :skip 
  test "Un administrateur peut attribuer un parrain" do
    # 
    # -PHOTOGRAPHIE-
    # Ce test produit la photographie "evaluation-book/3-parrain-et-start-eval"
    # qui permettra aux membres du comité du premier collège de choisir le
    # livre pour l'évaluer.
    # 

    %{procedure: procedure} = bddshot("evaluation-book/2-autorisation-auteur")

    book_id = procedure.data["book_id"]
    book = LdQ.Library.Book.get(book_id, [:parrain_id])

    # --- Vérifications préliminaires ---
    assert(is_nil(book.parrain_id))

    point_test = now()

    admin = make_admin() # ou renvoie celui qui existe

    # Membre choisi pour être parrain
    membres = LdQ.Comptes.Getter.get_users(member: true) 


    membre = 
      try do
        membres
        |> Enum.reject(fn member -> member.credit < 300 end)
        |> Enum.random()
      rescue 
        # Dans le cas où il n'y ait vraiment aucun membre avec un
        # crédit suffisant
        Enum.EmptyError ->
          Enum.random(membres)
      end

    admin = admin
    |> rejoint_la_page("/proc/#{procedure.id}")
    |> et_voit("h3", "Choix du parrain")
    |> choisit_option(membre.id, "book_parrain_id")
    |> clique_le_bouton("Attribuer ce parrain")
    |> pause(1)
    |> et_voit("h3", "Attribution du parrain")
    |> pause(1)


    # --- Vérifications ---

    res =
      membre
      |> recoit_un_mail(after: point_test, mail_id: "to_membre-demande-parrainage")

    # Le membre parrain augmente son crédit
    points_parrainage = LdQ.Evaluation.Numbers.points_for(:parrainage)
    old_credit = membre.credit
    new_credit = LdQ.Comptes.Getters.get_user!(membre.id).credit
    err_msg = 
      cond do
      new_credit == old_credit ->
        "Le nombre de points de crédit du membre choisi comme parrain aurait dû être augmenté. Il n'a pas changé."
      new_credit == old_credit + points_parrainage ->
        ""
      true -> 
        "Le nombre de points de crédit du membre choisi comme parrain aurait dû être augmenté. Il était de #{old_credit}, il est maintenant de #{new_credit}. Le nombre de points accordés pour un parrainage est de #{points_parrainage}."
      end
    assert(new_credit == old_credit + points_parrainage, err_msg)

    # Le livre a son parrain
    book = LdQ.Library.Book.get(book_id, [:title, :parrain_id, :last_phase, :current_phase])
    refute(is_nil(book.parrain_id))
    assert(book.parrain_id == membre.id, "Le livre devrait avoir maintenant comme parrain le membre choisi. Or son parrain est #{book.parrain_id} tandis que le membre a l'identifiant #{membre.id}…")
    # La phase du livre est la bonne
    assert(book.current_phase == 18)
    assert(book.last_phase == 15)

    # ==== IL LANCE ENSUITE L'ÉVALUATION ====

    admin # avec session
    |> clique_le_bouton("Lancer l'évaluation du livre")
    |> pause(1)

    # Un trigger a été implémanté pour se déclencher que le livre
    # reste trop longtemps en attente de lecteurs pour le lire
    assert_trigger(after: point_test, type: "deadline-quorum-college-1", content: [book.id])
    assert_trigger_log(after: point_test, typeop: "CREATRIGGER", type: "deadline-quorum-college-1", content: [book.id])

    # Les lecteurs du premier collège ont été informés
    assert_mailing_sent(:college1, "new-book-to-evaluate", after: point_test)

    # Une annonce a été produite
    assert_activity(after: point_test, public: true, content: "Mise en évaluation du livre “#{book.title}”")

    # La phase du livre est la bonne
    book = LdQ.Library.Book.get(book_id, [:last_phase, :current_phase])
    assert(book.current_phase == 20)
    assert(book.last_phase == 18)

    # Photographie de la base de donnée
    bddshot("evaluation-book/3-parrain-et-start-eval", %{
      procedure: procedure,
      book_id: book_id,
      parrain_id: membre.id
    })
  end
  
end